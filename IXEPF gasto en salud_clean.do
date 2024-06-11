
cd "C:\Users\danim\OneDrive\1.-Work\Seguros de salud\Bases de Datos\EPF\IX\Nueva carpeta"

use "base-gastos-ix-epf-stata.dta", clear
unique folio // 15135
unique folio if ccif == "12.1.2.01.01" // 1763
gen SVS_0 = 0
replace SVS_0 = 1 if ccif == "12.1.2.01.01"
keep SVS folio fe
duplicates drop
unique folio
bysort folio: egen SVS = max(SVS_0)
drop SVS_0
duplicates drop
count
tab SVS
save "Identificador_SVS.dta", replace // identificador de hogar con al menos un SVS
use "base-personas-ix-epf-stata.dta", clear
gen FONASA_1 = .
replace FONASA_1 = 1 if sp02 <= 5 & sp02 >= 1 & parentesco == 1
replace FONASA_1 = 0 if sp02 == 7 & parentesco == 1
gen FONASA_2 = .
replace FONASA_2 = 1 if sp02 <= 5 & sp02 >= 1 
replace FONASA_2 = 0 if sp02 == 7 
bysort folio: egen FONASA = max(FONASA_1)
replace FONASA_2 = FONASA if sp02 == -77 
keep folio nper FONASA_2 persona
rename FONASA_2 FONASA
duplicates drop
merge m:1 folio using Identificador_SVS, nogen
label variable FONASA "Previsión sustentador/a del hogar"
save Identificador_SVS_v2, replace
keep folio npersonas
duplicates drop
save Identificador_SVS_nper, replace

*Gastos del hogar
use "base-gastos-ix-epf-stata.dta", clear
merge m:1 folio using Identificador_SVS, nogen
merge m:1 folio using Identificador_SVS_nper, nogen
merge m:m folio using Identificador_SVS_v2, nogen
*svy set
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)
gen gasto_alim = 0
replace gasto_alim = gasto if d == "01"
gen gasto_vicios = 0
replace gasto_vicios = gasto if d == "02"
gen gasto_vestuario = 0
replace gasto_vestuario = gasto if d == "03"
gen gasto_vivienda = 0
replace gasto_vivienda = gasto if d == "04"
gen gasto_muebles = 0
replace gasto_muebles = gasto if d == "05"
gen gasto_salud = 0
replace gasto_salud = gasto if d == "06"
replace gasto_salud = gasto if ccif == "12.1.2.01.01"
gen gasto_transpo = 0
replace gasto_transpo = gasto if d == "07"
gen gasto_comunicaiones = 0
replace gasto_comunicaiones = gasto if d == "08"
gen gasto_cultura = 0
replace gasto_cultura = gasto if d == "09"
gen gasto_educacion = 0
replace gasto_educacion = gasto if d == "10"
gen gasto_hoteleria = 0
replace gasto_hoteleria = gasto if d == "11"
gen gasto_financiero = 0
replace gasto_financiero = gasto if d == "12"
gen gasto_servicios = 0
replace gasto_servicios = gasto if d == "13"
drop if d == "04" & g == "2"
collapse (sum) gasto gasto_alim gasto_vicios gasto_vestuario gasto_vivienda gasto_muebles gasto_salud gasto_transpo gasto_comunicaiones gasto_cultura gasto_educacion gasto_hoteleria gasto_financiero gasto_servicios, by(folio estrato_muestreo var_unit npersonas FONASA SVS fe)
save "gg_TOTAL.dta", replace

	   
*% de gasto
use "gg_TOTAL.dta", clear
drop if fe == .
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)

gen prop_salud = (gasto_salud/gasto)*100 
drop if prop_salud == .

mean prop if SVS == 0 & FONASA == 1 [aw=fe]
mean prop if SVS == 1 & FONASA == 1 [aw=fe]
mean prop if SVS == 0 & FONASA == 0 [aw=fe]
mean prop if SVS == 1 & FONASA == 0 [aw=fe]
mean prop [aw=fe]

collapse (mean) gasto_salud gasto prop_salud (sd) sd=prop_salud (count) n=prop_salud [aw=fe], by(SVS FONASA)

gen hi_prop_salud = prop_salud + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_prop_salud = prop_salud - invttail(n-1,0.025)*(sd/sqrt(n))

gen prop_salud_2 = string(prop_salud, "%5.2f") + "%"

gen SVS_FONASA = .
replace SVS_FONASA = 1 if SVS == 0 & FONASA == 1
replace SVS_FONASA = 2 if SVS == 1 & FONASA == 1
replace SVS_FONASA = 3 if SVS == 0 & FONASA == 0
replace SVS_FONASA = 4 if SVS == 1 & FONASA == 0

twoway (bar prop_salud SVS_FONASA if SVS_FONASA == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar prop_salud SVS_FONASA if SVS_FONASA == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar prop_salud SVS_FONASA if SVS_FONASA == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar prop_salud SVS_FONASA if SVS_FONASA == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter prop_salud SVS_FONASA, mlabel(prop_salud_2) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_prop_salud lo_prop_salud SVS_FONASA, color(gray) ylabel(0(2)10)) ///  
	   ,  ylabel(, format(%5.0f) angle(0) )  ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   graphregion(fcolor(white)) name(x12, replace)  scale(.6) xtitle("") ytitle("Porcentaje") legend(off) xlabel(,grid) 

**GG salud por subclase
use "base-gastos-ix-epf-stata.dta", clear
merge m:1 folio using Identificador_SVS, nogen
merge m:1 folio using Identificador_SVS_nper, nogen
merge m:m folio using Identificador_SVS_v2, nogen
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)
keep if d == "06" | ccif == "12.1.2.01.01"
gen medicamentos = 0
replace medicamentos = gasto if g == "1" & c == "1"  & d == "06" 
gen productos_medicos = 0
replace productos_medicos = gasto if g == "1" & c == "2" & d == "06" 
gen productos_asistencia = 0
replace productos_asistencia = gasto if g == "1" & c == "3" & d == "06" 
gen mantenimiento = 0
replace mantenimiento = gasto if g == "1" & c == "4" & d == "06" 
gen preventiva = 0
replace preventiva = gasto if g == "2" & c == "1" & d == "06" 
gen dentales = 0
replace dentales = gasto if g == "2" & c == "2" & d == "06" 
gen ambulatorios = 0
replace ambulatorios = gasto if g == "2" & c == "3" & d == "06" 
gen rehabilitacion = 0
replace rehabilitacion = gasto if g == "3" & c == "1" & d == "06" 
gen hospitalizados = 0
replace hospitalizados = gasto if g == "3" & c == "2" & d == "06" 
gen imagenes = 0
replace imagenes = gasto if g == "4" & c == "1" & d == "06" 
gen transporte_emergencia = 0
replace transporte_emergencia = gasto if g == "4" & c == "2" & d == "06" 
gen no_desglosado = 0
replace no_desglosado = gasto if g == "5" & c == "1" & d == "06" 
gen gg_svs = 0
replace gg_svs = gasto if ccif == "12.1.2.01.01"

collapse (sum) gasto medicamentos productos_medicos productos_asistencia mantenimiento preventiva dentales ambulatorios rehabilitacion hospitalizados imagenes transporte_emergencia no_desglosado gg_svs, by(folio estrato_muestreo var_unit npersonas FONASA SVS fe)
save "gg_salud_TOTAL.dta", replace

*% de gasto
use "gg_salud_TOTAL.dta", clear
drop if fe == .
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)

egen ggtot = rowtotal(medicamentos productos_medicos productos_asistencia mantenimiento preventiva dentales ambulatorios rehabilitacion hospitalizados imagenes transporte_emergencia no_desglosado gg_svs)

collapse (mean) medicamentos productos_medicos productos_asistencia mantenimiento preventiva dentales ambulatorios rehabilitacion hospitalizados imagenes transporte_emergencia no_desglosado gg_svs ggtot [aw=fe], by(SVS FONASA)

foreach a in medicamentos productos_medicos productos_asistencia mantenimiento preventiva dentales ambulatorios rehabilitacion hospitalizados imagenes transporte_emergencia no_desglosado gg_svs ggtot{
	gen prop_`a' = (`a'/ggtot)*100 
}


gen SVS_FONASA = .
replace SVS_FONASA = 1 if SVS == 0 & FONASA == 1
replace SVS_FONASA = 2 if SVS == 1 & FONASA == 1
replace SVS_FONASA = 3 if SVS == 0 & FONASA == 0
replace SVS_FONASA = 4 if SVS == 1 & FONASA == 0

keep if SVS_FONASA != . // nos centraremos en el personas con previsiones de salud FONASA o ISAPRE

*para apilarlos
gen A = prop_medicamentos 
gen B = prop_medicamentos + prop_productos_medicos 
gen C = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia 
gen D = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento 
gen E = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva 
gen F = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales 
gen G = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios 
gen H = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion 
gen I = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados 
gen J = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes 
gen K = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes + prop_transporte_emergencia 
gen L = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes + prop_transporte_emergencia + prop_no_desglosado 
gen M = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes + prop_transporte_emergencia + prop_no_desglosado + prop_gg_svs


*Para las etiquetas de las barras
gen A2 = prop_medicamentos/2 
gen B2 = prop_medicamentos + prop_productos_medicos/2 
gen C2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia/2 
gen D2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento/2 
gen E2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva/2 
gen F2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales/2 
gen G2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios/2 
gen H2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion/2 
gen I2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados/2 
gen J2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes/2 
gen K2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes + prop_transporte_emergencia/2 
gen L2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes + prop_transporte_emergencia + prop_no_desglosado/2 
gen M2 = prop_medicamentos + prop_productos_medicos + prop_productos_asistencia + prop_mantenimiento + prop_preventiva + prop_dentales + prop_ambulatorios + prop_rehabilitacion + prop_hospitalizados + prop_imagenes + prop_transporte_emergencia + prop_no_desglosado + prop_gg_svs/2


twoway (bar A SVS_FONASA, bcolor(teal*0.25) barwidth(0.8)) /// 
	   (rbar A B SVS_FONASA, bcolor(teal*0.5) barwidth(0.8)) /// 
	   (rbar B C SVS_FONASA, bcolor(teal*0.75) barwidth(0.8)) /// 
	   (rbar C D SVS_FONASA, bcolor(teal*1) barwidth(0.8)) ///
	   (rbar D E SVS_FONASA, bcolor(olive_teal*0.1) barwidth(0.8)) ///
	   (rbar E F SVS_FONASA, bcolor(olive_teal*0.4) barwidth(0.8)) ///
	   (rbar F G SVS_FONASA, bcolor(olive_teal*0.9) barwidth(0.8)) ///
	   (rbar G H SVS_FONASA, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (rbar H I SVS_FONASA, bcolor(emidblue*0.9) barwidth(0.8)) ///
	   (rbar I J SVS_FONASA, bcolor(ltblue*0.8) barwidth(0.8)) ///
	   (rbar J K SVS_FONASA, bcolor(ltblue*0.2) barwidth(0.8)) ///
	   (rbar K L SVS_FONASA, bcolor(bluishgray*1) barwidth(0.8)) ///
	   (rbar L M SVS_FONASA, bcolor(navy*0.2) barwidth(0.8)) ///
	   (scatter A2 SVS_FONASA, mlabel(prop_medicamentos) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall))  /// 
	   (scatter B2 SVS_FONASA, mlabel(prop_productos_medicos) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter C2 SVS_FONASA, mlabel(prop_productos_asistencia) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter D2 SVS_FONASA, mlabel(prop_mantenimiento) msymbol(i) mlabposition(9) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter E2 SVS_FONASA, mlabel(prop_preventiva) msymbol(i) mlabposition(3) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter F2 SVS_FONASA, mlabel(prop_dentales) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter G2 SVS_FONASA, mlabel(prop_ambulatorios) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter H2 SVS_FONASA, mlabel(prop_rehabilitacion) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter I2 SVS_FONASA, mlabel(prop_hospitalizados) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter J2 SVS_FONASA, mlabel(prop_imagenes) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter K2 SVS_FONASA, mlabel(prop_transporte_emergencia) msymbol(i) mlabposition(9) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter L2 SVS_FONASA, mlabel(prop_no_desglosado) msymbol(i) mlabposition(3) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)) /// 
	   (scatter M2 SVS_FONASA, mlabel(prop_gg_svs) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(vsmall)), /// 
	   ylabel(0(20)100, angle(0) labsize(small)) xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Porcentaje", size(small)) graphregion(fcolor(white))  name(x13, replace)  /// 
	   scale(.6) xtitle("") ///
	   legend(order(13 12 11 10 9 8 7 6 5 4 3 2 1) label(1 "Medicamentos") label(2 "Productos médicos") label(3 "Productos de asistencia") label(4 "Reparación, arriendo y" "mantenimiento de" "productos médicos") label(5 "Servicios de atención preventiva") label(6 "Servicios dentales ambulatorios") label(7 "Otros servicios ambulatorios") label(8 "Servicios curativos y" "de rehabilitación hospitalizados") label(9 "Cuidados de largo plazo" "hospitalizados") label(10 "Servicios de diagnóstico por" "imagen y de laboratorio médico") label(11 "Servicios de transporte" "de emergencia") label(12 "Gastos no desglosados") label(13 "Seguros de salud") rows(13) position(3) size(small)) 
	   
	      
*****GASTO PROMEDIO EN SVS FONASA ISAPRE
*% de gasto
use "gg_salud_TOTAL.dta", clear
drop if fe == .
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)
egen gg_salud = rowtotal(medicamentos productos_medicos productos_asistencia mantenimiento preventiva dentales ambulatorios rehabilitacion hospitalizados imagenes transporte_emergencia no_desglosado)
gen gg_svs_pc = gg_svs/npersonas
gen gg_salud_pc = gg_salud/npersonas
drop if FONASA == .
bysort FONASA: sum gg_svs_pc gg_salud_pc if SVS == 1 [aw=fe]
bysort FONASA: sum gg_salud_pc [aw=fe]

gen SVS_FONASA = .
replace SVS_FONASA = 1 if SVS == 0 & FONASA == 1 // sin seguro con fonasa
replace SVS_FONASA = 2 if SVS == 0 & FONASA == 0 // sin seguro con isapre
replace SVS_FONASA = 3 if SVS == 1 & FONASA == 1 // con seguro con fonasa
replace SVS_FONASA = 4 if SVS == 1 & FONASA == 0 // con seguro con isapre


foreach i of varlist gg_svs_pc gg_salud_pc {  
		   svy, subpop(if SVS_FONASA == 1): mean `i' // "sin seguro con fonasa"
           matrix A1`i' = r(table)
           matrix b1`i' = A1`i'[1,1]
           matrix l1`i' = A1`i'[5,1]
           matrix u1`i' = A1`i'[6,1]
		   svy, subpop(if SVS_FONASA == 2): mean `i'  // "sin seguro con isapre"
           matrix A2`i' = r(table)
           matrix b2`i' = A2`i'[1,1]
           matrix l2`i' = A2`i'[5,1]
           matrix u2`i' = A2`i'[6,1]
		   svy, subpop(if SVS_FONASA == 3): mean `i'  // "con seguro con fonasa"
           matrix A3`i' = r(table)
           matrix b3`i' = A3`i'[1,1]
           matrix l3`i' = A3`i'[5,1]
           matrix u3`i' = A3`i'[6,1]
		   svy, subpop(if SVS_FONASA == 4): mean `i'  // con seguro con isapre
           matrix A4`i' = r(table)
           matrix b4`i' = A4`i'[1,1]
           matrix l4`i' = A4`i'[5,1]
           matrix u4`i' = A4`i'[6,1]
   }

putexcel set Tabla_sum_fonasa_EPF_ggSVS, modify

putexcel C2 = matrix(A1gg_svs_pc)
putexcel D2 = matrix(A1gg_salud_pc)

putexcel C12 = matrix(A2gg_svs_pc)
putexcel D12 = matrix(A2gg_salud_pc)

putexcel C22 = matrix(A3gg_svs_pc)
putexcel D22 = matrix(A3gg_salud_pc)

putexcel C32 = matrix(A4gg_svs_pc)
putexcel D32 = matrix(A4gg_salud_pc)

**
*Este excel tiene una tabla que ordena la información que llegará con las tablas recién armadas, solo se debe volver a importar
clear all
**
import excel "C:\Users\danim\OneDrive\1.-Work\Seguros de salud\Bases de Datos\EPF\IX\Tabla_sum_fonasa_EPF_ggSVS.xlsx", sheet("Sheet1") cellrange(H2:K14) firstrow clear
rename (SVS_FONASA gg_svs gg_salud) (svs_fonasa gg_svs_pc gg_salud_pc)
reshape wide gg_svs_pc gg_salud_pc, i( svs_fonasa) j( variable) string
gen SVS_FONASA = 1 if svs_fonasa == 1
replace SVS_FONASA = 2 if svs_fonasa == 3
replace SVS_FONASA = 3 if svs_fonasa == 2
replace SVS_FONASA = 4 if svs_fonasa == 4

gen SVS_FONASA_2 = .
replace SVS_FONASA_2 = 1 if SVS_FONASA == 2
replace SVS_FONASA_2 = 2 if SVS_FONASA == 4

gen gg_salud_pcb_2 = "$" + string(gg_salud_pcb, "%9.0f") 
gen gg_svs_pcb_2 = "$" + string(gg_svs_pcb, "%9.0f") 

gen A = gg_salud_pcb 
gen B = gg_salud_pcb + gg_svs_pcb

gen A2 = gg_salud_pcb/2 
gen B2 = gg_salud_pcb + gg_svs_pcb/2

twoway (bar A SVS_FONASA, bcolor(teal*0.3) barwidth(0.8)) /// 
	   (rbar A B SVS_FONASA, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A2 SVS_FONASA, mlabel(gg_salud_pcb_2) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(small))  /// 
	   (scatter B2 SVS_FONASA if SVS_FONASA == 2 | SVS_FONASA == 4, mlabel(gg_svs_pcb_2) msymbol(i) mlabposition(0) mlabformat(%5.2f) mlabcolor(black) mlabsize(small)), /// 
	   ylabel(0(20000)140000, angle(0) labsize(small)) xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("CLP", size(small)) graphregion(fcolor(white)) xlabel(,grid) name(x12, replace)  /// 
	   scale(.6) xtitle("") legend(order(1 2) label(1 "Gasto en salud") label(2 "Gasto en SVS"))

*Gasto catastrófico
use "base-gastos-ix-epf-stata.dta", clear
merge m:1 folio using Identificador_SVS, nogen
merge m:1 folio using Identificador_SVS_nper, nogen
merge m:m folio using Identificador_SVS_v2, nogen
*svy set
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)
gen gg_subs = 112167.41
gen gasto_alim = 0
replace gasto_alim = gasto if d == "01"
gen gasto_salud = 0
replace gasto_salud = gasto if d == "06"
replace gasto_salud = gasto if ccif == "12.1.2.01.01"

drop if d == "04" & g == "2" // aliminando arriendos imputados!!
drop if fe == .
drop if npersonas == .

collapse (sum) gasto gasto_alim gasto_salud, by(folio estrato_muestreo var_unit npersonas FONASA SVS fe gg_subs)

gen gasto_alim_pc = gasto_alim/nper
gen capacidad_pago2 = .
replace capacidad_pago2 = gasto - gasto_alim if gg_subs > gasto_alim_pc
replace capacidad_pago2 = gasto - gg_subs*(npersonas^0.7) if gg_subs <= gasto_alim_pc

gen prop_salud = (gasto_salud/capacidad_pago2)*100 // 2 con capacidad_pago cero
drop if prop_salud == .

gen gg_catastrofico = .
replace gg_catastrofico = 1 if prop_salud > 30 & prop_salud < .
replace gg_catastrofico = 0 if prop_salud <= 30

gen SVS_FONASA = .
replace SVS_FONASA = 1 if SVS == 0 & FONASA == 1
replace SVS_FONASA = 2 if SVS == 1 & FONASA == 1
replace SVS_FONASA = 3 if SVS == 0 & FONASA == 0
replace SVS_FONASA = 4 if SVS == 1 & FONASA == 0
drop if SVS_FONASA == . // 2926 folios

keep gg_catastrofico prop_salud SVS_FONASA folio fe
reshape wide gg_catastrofico prop_salud, i(folio fe) j(SVS_FONASA)

collapse (mean) gg_catastrofico1 gg_catastrofico2 gg_catastrofico3 gg_catastrofico4 /// 
		 (sd) sdgg_catastrofico1=gg_catastrofico1 sdgg_catastrofico2=gg_catastrofico2 sdgg_catastrofico3=gg_catastrofico3 sdgg_catastrofico4=gg_catastrofico4 ///
		 (count) ngg_catastrofico1=gg_catastrofico1 ngg_catastrofico2=gg_catastrofico2 ngg_catastrofico3=gg_catastrofico3 ngg_catastrofico4=gg_catastrofico4 [aw=fe]

foreach a in gg_catastrofico1 gg_catastrofico2 gg_catastrofico3 gg_catastrofico4{
gen hi_`a' = (`a' + invttail(n`a'-1,0.025)*(sd`a'/sqrt(n`a')))*100
gen lo_`a' = (`a' - invttail(n`a'-1,0.025)*(sd`a'/sqrt(n`a')))*100
}
gen x = 1
reshape long gg_catastrofico sdgg_catastrofico ngg_catastrofico hi_gg_catastrofico lo_gg_catastrofico, j(grupo) i(x)
gen gg_catastrofico1 = gg_catastrofico*100
gen gg_catastrofico2 = string(gg_catastrofico1, "%5.2f") + "%"

twoway (bar gg_catastrofico1 grupo if grupo == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar gg_catastrofico1 grupo if grupo == 2, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (bar gg_catastrofico1 grupo if grupo == 3, bcolor(emidblue*0.4) barwidth(0.8)) /// 
	   (bar gg_catastrofico1 grupo if grupo == 4, bcolor(emidblue*0.8) barwidth(0.8)) /// 
	   (scatter gg_catastrofico1 grupo, mlabel(gg_catastrofico2) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_gg_catastrofico lo_gg_catastrofico grupo, color(gray)), ///
	   ylabel(0(1)8, angle(0)) xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0)) ///
	   legend(off) ytitle("Porcentaje") graphregion(fcolor(white))   name(catas1, replace)  /// 
	   scale(.7) xtitle("") xlabel(,grid) title("Umbral de 30%")

use "base-gastos-ix-epf-stata.dta", clear
merge m:1 folio using Identificador_SVS, nogen
merge m:1 folio using Identificador_SVS_nper, nogen
merge m:m folio using Identificador_SVS_v2, nogen
*svy set
svyset var_unit [w=fe], psu(var_unit) strata(estrato_muestreo) singleunit(certainty)
gen gg_subs = 112167.41
gen gasto_alim = 0
replace gasto_alim = gasto if d == "01"
gen gasto_salud = 0
replace gasto_salud = gasto if d == "06"
replace gasto_salud = gasto if ccif == "12.1.2.01.01"

drop if d == "04" & g == "2" // aliminando arriendos imputados!!
drop if fe == .
drop if npersonas == .

collapse (sum) gasto gasto_alim gasto_salud, by(folio estrato_muestreo var_unit npersonas FONASA SVS fe gg_subs)

gen gasto_alim_pc = gasto_alim/nper
gen capacidad_pago2 = .
replace capacidad_pago2 = gasto - gasto_alim if gg_subs > gasto_alim_pc
replace capacidad_pago2 = gasto - gg_subs*(npersonas^0.7) if gg_subs <= gasto_alim_pc

gen prop_salud = (gasto_salud/capacidad_pago2)*100 // 2 con capacidad_pago cero
drop if prop_salud == .

gen gg_catastrofico = .
replace gg_catastrofico = 1 if prop_salud > 40 & prop_salud < .
replace gg_catastrofico = 0 if prop_salud <= 40

gen SVS_FONASA = .
replace SVS_FONASA = 1 if SVS == 0 & FONASA == 1
replace SVS_FONASA = 2 if SVS == 1 & FONASA == 1
replace SVS_FONASA = 3 if SVS == 0 & FONASA == 0
replace SVS_FONASA = 4 if SVS == 1 & FONASA == 0
drop if SVS_FONASA == . // 2926 folios

keep gg_catastrofico prop_salud SVS_FONASA folio fe
reshape wide gg_catastrofico prop_salud, i(folio fe) j(SVS_FONASA)

collapse (mean) gg_catastrofico1 gg_catastrofico2 gg_catastrofico3 gg_catastrofico4 /// 
		 (sd) sdgg_catastrofico1=gg_catastrofico1 sdgg_catastrofico2=gg_catastrofico2 sdgg_catastrofico3=gg_catastrofico3 sdgg_catastrofico4=gg_catastrofico4 ///
		 (count) ngg_catastrofico1=gg_catastrofico1 ngg_catastrofico2=gg_catastrofico2 ngg_catastrofico3=gg_catastrofico3 ngg_catastrofico4=gg_catastrofico4 [aw=fe]

foreach a in gg_catastrofico1 gg_catastrofico2 gg_catastrofico3 gg_catastrofico4{
gen hi_`a' = (`a' + invttail(n`a'-1,0.025)*(sd`a'/sqrt(n`a')))*100
gen lo_`a' = (`a' - invttail(n`a'-1,0.025)*(sd`a'/sqrt(n`a')))*100
}
gen x = 1
reshape long gg_catastrofico sdgg_catastrofico ngg_catastrofico hi_gg_catastrofico lo_gg_catastrofico, j(grupo) i(x)
gen gg_catastrofico1 = gg_catastrofico*100
gen gg_catastrofico2 = string(gg_catastrofico1, "%5.2f") + "%"

twoway (bar gg_catastrofico1 grupo if grupo == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar gg_catastrofico1 grupo if grupo == 2, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (bar gg_catastrofico1 grupo if grupo == 3, bcolor(emidblue*0.4) barwidth(0.8)) /// 
	   (bar gg_catastrofico1 grupo if grupo == 4, bcolor(emidblue*0.8) barwidth(0.8)) /// 
	   (scatter gg_catastrofico1 grupo, mlabel(gg_catastrofico2) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_gg_catastrofico lo_gg_catastrofico grupo, color(gray)), ///
	   ylabel(0(1)8, angle(0)) xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0)) ///
	   legend(off) ytitle("Porcentaje") graphregion(fcolor(white))   name(catas2, replace)  /// 
	   scale(.7) xtitle("") title("Umbral de 40%") xlabel(,grid)
	   
graph combine catas1 catas2, ycommon iscale(0.9) graphregion(fcolor(white)) xsize(10)