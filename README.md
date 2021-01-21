# recodespecify

Stata program that Recodes other specify (Single select and multiple select)

## Overview

Data officers/Managers might want to convert a dataset with repeat groups from long to wide 
This stata program de-identify data and labels some variables

## installation(Beta)

```stata
net install recodespecify, all replace ///
	from("https://raw.githubusercontent.com/mbidinlib/recodespecify/master/ado")
```

## Syntax

```stata

recodspecify ///
	using "datafile", ///
	xlsheet("excel file with recode") ///
	parent(parent) ///
	childvar(child) ///
	childval(child_value)
	newcat(new_category)
	parenttype(multiple/single)	
	save(finaldata.dta)

```


