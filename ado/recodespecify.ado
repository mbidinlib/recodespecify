
**************************************
*By 	Mathew Bidinlib
*Date:  November 11 2020
**************************************
clear
set seed 12345
version 15.0


cap program drop recodespecify
program define recodespecify

	#delimit ;
	
    syntax using/ ,
		    XLSheet(string)
		   [PARENTvar(name)]
		   [CHILDvar(name)]
		   [CHILDVal(name)]
		   [RECODEto(name)]
		   [NEWcat(name)]
		   [PARENTType(name)]
		   [save(string)]
		   ;
	#delimit cr

	
	cls
	qui{
	
		* Check using data is in stata format
		if !regexm(`"`using'"', ".dta$") {
			noi di as err "Invalid data format: the using file should be a .dta file"
			error 603
		}
		
		* Check XLSheet is an excel file
		if !regexm("`xlsheet'", ".xls$|.xlsx$|.xlsm$") {
			noi di as err "Invalid sheet format: the xlsheet must be a .xls , .xlsx or .xlsm format"
			error 603
		}
	
		* Set default column names
		if "`parentvar'" 	== "" loc parentvar 	"parent"
		if "`childvar'" 	== "" loc childvar 		"child"
		if "`childval'" 	== "" loc childval 		"child_value"
		if "`recodeto'" 	== "" loc recodeto 		"recode_to"
		if "`parenttype'"  	== "" loc parenttype	"parent_type"
		if "`newcat'" 	 	== "" loc newcat		"new_category"
		
		*Initial import and 
		* sorting multpile vs single
		*===========================		
		noi di "{hline}"
		noi di "Importing excel sheet"

		import excel "`xlsheet'", clear first
		
		
		* Confirm variables
		********************
		loc xlvars "`parentvar' `childvar' `childval' `recodeto' `parenttype' `newcat'"
		
		foreach varss of local xlvars {
			cap confirm var `varss'
			if _rc {
				noi di as err "Variable: `varss' not found"
				error 101
			}
		}
		
		drop if mi(`recodeto')   
		preserve
		keep if `parenttype' == "MULTIPLE" | `parenttype' == "m" | regex(`parenttype',"ultiple")
		tempfile multiple_select
		save `multiple_select', emptyok replace
		restore
		drop if `parenttype' == "MULTIPLE" | `parenttype' == "m" | regex(`parenttype',"ultiple")

		
		*==================
		* Singe Select
		*==================
		
		if _N >=1 {

			noi di ""
			noi di "Working with single select variables"
			
			local n_recodes = _N
			foreach k of varl _all {
				forval j = 1/`n_recodes'{
					global `k'_`j'  = `k'[`j']
				}
			}

			* Generate globals new categories
			drop if mi(`newcat')
			duplicates drop `parentvar' `recodeto', force

			loc cnt = _N
			forval j = 1/`cnt'{
				global `parentvar'__`j'  = `parentvar'[`j']
				global `recodeto'__`j'  = `recodeto'[`j']
				global `newcat'__`j'  = `newcat'[`j']
			}

			
			use "`using'", clear

			*********************************
			* Apply recode for Single select
			*********************************

			noi di "Creating new categories"

			*create new category
			forval j = 1/`cnt'{

				loc ${`parentvar'__`j'}_val "`:val lab ${`parentvar'__`j'}'"
				label define `${`parentvar'__`j'}_val' ${`recodeto'__`j'} "${`newcat'__`j'}", add
				if _rc{
					di as err "Value label (value:${`recodeto'__`j'}) already exists for ${`parentvar'__`j'}. Cannot be added as new. Change the new value and rerun"
					error 198
				}
				
				noi di "Val (${`recodeto'__`j'}) with label (${`newcat'__`j'}) added to ${`parentvar'__`j'}" 

			}

			noi di ""
			noi di "Applying recodes to data"			
			* Apply recode
			forval j = 1/`n_recodes'{
				replace ${`parentvar'_`j'} = ${`recodeto'_`j'} if ${`childvar'_`j'} == "${`childval'_`j'}" 
			}
			
			tempfile usingdata
			save `usingdata', replace
		}

		* If there is no single select
		else 	{
			loc usingdata "`using'"
			noi di "There is no single select variable to work with- program skipping to multiple"
		}
		
		
		*****************
		*Multiple select
		*****************

		use `multiple_select', clear

		if _N >=1 {
		noi di ""
		noi di "{hline}"
		noi di "Working with Multiple select variables"

			loc n_recodes = _N
			* save details of sheet as global
			foreach k of varl _all {
				forval j = 1/`n_recodes'{
					global `k'_`j'  = `k'[`j']
				}
			}

			drop if mi(`newcat')
			duplicates drop `parentvar' `recodeto', force

			*save new names in local
			*======================
			loc num_cats = _N
			forval k = 1/`num_cats'{
			
				loc p_name 			= `parentvar'[`k']
				loc p_names			= "`p_names' `p_name'"
				loc new_cat_v 		= `recodeto'[`k']
				loc new_cat_lab_`k' = `newcat'[`k']
				loc new_childs  "`new_childs'  `p_name'_`new_cat_v'"
			}

			 *Create new split variables
			 *===========================
			
			use "`usingdata'", clear
			
			noi di " Generating new split variables"
			
			loc nvar_count : word count `new_childs'
			forval v = 1/`nvar_count'{
				loc nvar : word `v' of `new_childs'
				loc pvar : word `v' of `p_names'
				
				gen `nvar' = . , a(`p_var')  	// generate variable as missing	
				replace `nvar' = 0 if !mi(`pvar') 	// replace with 0 where question is relevant
				
				noi di "New variable : `nvar'  generated"
			}
					
			noi di "Applying recode to data"					
			* Apply recode
			forval j = 1/`n_recodes'{
				loc v_name = "${`parentvar'_`j'}_${`recodeto'_`j'}"
				glo v_name_n = subinstr("`v_name'","-", "_",.)
				replace ${v_name_n}  = 1   if ${`childvar'_`j'} == "${`childval'_`j'}" 
			}
			 
			 
			 * Order variables - if generate after fails to arrange
			 ******************************************************
			
			
			foreach parents_n of local p_names{
			
				order `parents_n'_*, after(`parents_n')
			}
			 
		}
		
		else noi di "No multiple select variable available-program skipping to end"

		if "`save'" != "" {
			save "`save'",replace
		}
	
	}
	
end
