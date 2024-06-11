clear all
* Datos ASOCIACION ASEGURADORES DE CHILE + POBLACIÓN INE
*https://app.powerbi.com/view?r=eyJrIjoiZjdiYjBkNGItYzMzYi00OWNkLWJmNGMtODlhYmVlMzE4NzgzIiwidCI6ImI2MzA2NjhmLWJjMDYtNGQ0Zi04M2NmLWM5NmY0MDNkOGQ0NSIsImMiOjR9
cd "C:\Users\danim\OneDrive\1.-Work\Seguros de salud\Bases de Datos\CMF\AACH"
import excel "C:\Users\danim\OneDrive\1.-Work\Seguros de salud\Bases de Datos\CMF\AACH\Asociacion.xlsx", sheet("Hoja2") cellrange(B2:O12) firstrow clear
save asociacion, replace

use asociacion, clear

tsset año
*correccion por seguros COVID 
gen prima2 = primadirecta/1000
clonevar prima3 = prima2 
replace prima3 = prima2 - (4793.118*0.3) if año == 2021
replace prima3 = prima2 - (5553.585*0.3) if año == 2022
replace prima3 = prima2 - (4223.433*0.3) if año == 2023

gen aseg2 = asegurados/1000
clonevar aseg3 = aseg2 
replace aseg3 = aseg2 - 4793.118 if año == 2021
replace aseg3 = aseg2 - 5553.585 if año == 2022
replace aseg3 = aseg2 - 4223.433 if año == 2023

tsline prima3, ylabel(15000(5000)40000, angle(0) grid glpattern(dash)) ytitle("Miles") legend(label(1 "Prima Directa (UF)")) xlabel(2014(1)2023,grid glpattern(dash)) xtitle("") graphregion(fcolor(white)) lcolor(blue red) name(x1, replace) 
gen aseg4 = (aseg3*1000)/12
format %9.0f aseg4
tsline  aseg4, ylabel(0(500000)3000000, angle(0) grid glpattern(dash)) ytitle("Número de beneficiarios") legend(label(1 "Prima Directa (UF)") label(2 "Asegurados")) xlabel(2014(1)2023,grid glpattern(dash)) xtitle("") graphregion(fcolor(white)) lcolor(blue red) name(x1, replace)


gen prop_aseg = (aseg4/poblacion_ine)*100
tsline  prop_aseg, ylabel(0(3)15, angle(0) grid glpattern(dash)) ytitle("Porcentaje de beneficiarios") legend(label(1 "Prima Directa (UF)") label(2 "Asegurados")) xlabel(2014(1)2023,grid glpattern(dash)) xtitle("") graphregion(fcolor(white)) lcolor(blue red) name(x2, replace)
graph combine x1 x2, graphregion(fcolor(white)) xsize(9) scale(1.1)

gen vig2 = polizasvig/1000 
gen emit2 = polizasemitidas/1000


clonevar vig3 = vig2 // suponiendo que las polizas duran un año como dice en el mail
replace vig3 = vig2 - 4793.118 if año == 2021
replace vig3 = vig2 - 5553.585 if año == 2022
replace vig3 = vig2 - 4223.433 if año == 2023
clonevar emit3 = emit2 // suponiendo que las polizas duran un año como dice en el mail
replace emit3 = emit2 - 4793.118 if año == 2021
replace emit3 = emit2 - 4130.135 if año == 2022
replace emit3 = emit2 - 2492.778 if año == 2023
clonevar vig4 = vig2 // suma anual
replace vig4 = vig2 - 4952.056 if año == 2022
replace vig4 = vig2 - 4102.276 if año == 2023


tsline vig3 emit3, ylabel(0(1000)5000, angle(0)) ytitle("Miles") legend(label(1 "Pólizas Vigentes") label(2 "Pólizas Emitidas")) xlabel(2014(1)2023,grid glpattern(dash)) xtitle("") graphregion(fcolor(white)) lcolor(blue red) name(x2, replace) ylabel(, glpattern(dash))


clonevar primapromedio3 = primapromedio
replace primapromedio3 = prima3/aseg3 if año >= 2021

tsline primapromedio3, ylabel(0.0(0.4)2, angle(0) format(%3.1f) glpattern(dash)) ytitle("UF") legend(label(1 "Prima Directa Promedio")) xlabel(2014(1)2023,grid glpattern(dash)) xtitle("") graphregion(fcolor(white)) lcolor(blue red)
gen prima4 = prima3*1000
gen aseg4_a = aseg3*1000
gen vig5 = vig3*1000
gen emit5 = emit3*1000
order año prima4 aseg4_a aseg4 primapromedio3 vig5 emit5

*https://www.latercera.com/pulso/noticia/el-empleo-presencial-llega-a-su-mayor-nivel-desde-principios-de-2021-y-teletrabajo-se-estabiliza-en-torno-a-10/Z2GF4Z423ZE65A5S26ALUTY2O4/
