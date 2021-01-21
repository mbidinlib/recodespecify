# recodespecify

Stata program that Recodes other specify (Single select and multiple select)

## Overview

During data cleaning, data officers/Managers might want to recode other specify in an excel sheet and apply to a stata dataset. This program will read the recodes from the excel file and apply it to the data

## installation(Beta)

```stata
net install recodespecify, all replace ///
	from("https://raw.githubusercontent.com/mbidinlib/recodespecify/master/ado")
```

## Syntax

```stata

recodspecify 				///
	using "datafile", 		///
	xlsheet("excel file with recode") ///
	parent(parent)			 ///
	childvar(child) 		///
	childval(child_value)		///
	recodeto(recode_to) 		///
	newcat(new_category) 		///
	parenttype(multiple/single)	///
	save(finaldata.dta)

```


