/* ANÁLISIS CASEN 2022 */

// Importar base de datos CASEN 2022 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2022/Base%20de%20datos%20Casen%202022%20STATA_18%20marzo%202024.dta.zip

/* Identificador núcleo */
tostring folio, gen(folio_s)
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/* SVS a nivel de núcleo y de persona */
/* svs -> Indica si alguien en el núcleo tiene svs */
gen svs = .
replace svs = 1 if s15 == 1
replace svs = 0 if s15 == 2
/* svs_p -> Indica si la persona vive en un núcleo en el que alguien tiene SVS */
bysort id_nucleo: egen svs_p = max(svs)

/* Educación */
gen educ_completa = "No sabe"
replace educ_completa = "Sin educación formal" if educ == 0 | educ == 1
replace educ_completa = "Básica" if educ == 2 | educ == 3 | educ == 4
replace educ_completa = "Media" if educ == 5 | educ == 6 | educ == 7 | educ == 9
replace educ_completa = "Técnico superior" if educ == 8 
replace educ_completa = "Profesional" if educ == 10 | educ == 11
replace educ_completa = "Posgrado" if educ == 12
encode educ_completa, gen(educ2)

/* Previsión (0=ISAPRE, 1=ISAPRE)*/
gen fonasa = .
replace fonasa = 1 if s13 == 1
replace fonasa = 0 if s13 == 2

/* Grupo etario*/
gen grupo_edad = .
replace grupo_edad = 1 if edad < 18
replace grupo_edad = 2 if edad >= 18 & edad < 25
replace grupo_edad = 3 if edad >= 25 & edad < 35
replace grupo_edad = 4 if edad >= 35 & edad < 45
replace grupo_edad = 5 if edad >= 45 & edad < 55
replace grupo_edad = 6 if edad >= 55 & edad < 65
replace grupo_edad = 7 if edad >= 65 & edad < 75
replace grupo_edad = 8 if edad >= 75

/* Sexo */
gen mujer = 0
replace mujer = 1 if sexo == 2

/* Empleo */
gen empleo = 0
replace empleo = 1 if o1 == 1 | o2 == 1 | o3 == 1

/* Zona (urbana o rural) */
gen urbano = 0
replace urbano = 1 if area == 1

/*Ingresos (usando Ingreso Autónomo Corregido)*/
clonevar yautcor2 = yautcor
replace yautcor2 = 0 if yautcor2 == .
gen yautcor2_miles=yautcor2/1000
gen x = 1
bysort id_nucleo: egen tot_nucleo = total(x) 
bysort id_nucleo: egen ingresos_tot = total(yautcor2)
bysort id_nucleo: egen ingresos_tot_miles = total(yautcor2_miles)
gen ingreso_pc = ingresos_tot/tot_nucleo
gen ingreso_pc_miles = ingresos_tot_miles/tot_nucleo

/* Combinación SVS y previsión, a nivel de núcleo y de persona */
gen svs_fonasa = .
replace svs_fonasa = 1 if svs == 0 & fonasa == 1 // sin seguro con fonasa
replace svs_fonasa = 2 if svs == 1 & fonasa == 1 // con seguro con fonasa
replace svs_fonasa = 3 if svs == 0 & fonasa == 0 // sin seguro con isapre
replace svs_fonasa = 4 if svs == 1 & fonasa == 0 // con seguro con isapre

gen svs_fonasa_p = .
replace svs_fonasa_p = 1 if svs_p == 0 & fonasa == 1 // sin seguro con fonasa
replace svs_fonasa_p = 2 if svs_p == 1 & fonasa == 1 // con seguro con fonasa
replace svs_fonasa_p = 3 if svs_p == 0 & fonasa == 0 // sin seguro con isapre
replace svs_fonasa_p = 4 if svs_p == 1 & fonasa == 0 // con seguro con isapre

/* Filtrar sólo las personas que tienen fonasa e isapre*/
keep if svs_fonasa_p != .

/* Gráfico combinación previsión y SVS  a nivel de persona */
preserve
collapse (sum) x [fw=expr], by(svs_fonasa_p)
egen total = total(x)
gen grupo = (x/total)*100

twoway (bar grupo svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (bar grupo svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (bar grupo svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) /// 
	   (bar grupo svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) /// 
	   (scatter grupo svs_fonasa_p, mlabel(grupo) msymbol(i) mlabposition(12) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)80, angle(0)) xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0)) /// 
	   legend(off) ytitle("Porcentaje") graphregion(fcolor(white))  name(x1, replace)  /// 
	   scale(.7) xtitle("") 
restore

/* Gráfico combinación previsión y SVS a nivel de persona, según sexo */
preserve
collapse (sum) x [fw=expr], by(sexo svs_fonasa_p)
bysort sexo: egen total = total(x)
gen mujer = (x/total)*100

reshape wide total x mujer, i(sexo) j(svs_fonasa_p)
gen A = mujer1
gen B = mujer1 + mujer2 
gen C = mujer1 + mujer2 + mujer3
gen D = mujer1 + mujer2 + mujer3 + mujer4

twoway (bar A sexo, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B sexo, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (rbar B C sexo, bcolor(emidblue*0.4) barwidth(0.8)) /// 
	   (rbar C D sexo, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter A sexo, mlabel(mujer1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B sexo, mlabel(mujer2) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter C sexo, mlabel(mujer3) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter D sexo, mlabel(mujer4) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) xlabel(1 "Hombre" 2 "Mujer", angle(0)) /// 
	   legend(order(1 2 3 4) label(1 "Sin SVS; FONASA") label(2 "Con SVS; FONASA") label(3 "Sin SVS; ISAPRE") label(4 "Con SVS; ISAPRE") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) name(x1, replace)  /// 
	   scale(.6) xtitle("")
restore

/* Gráfico combinación previsión y SVS a nivel de persona, según grupo etario */
gen svs_fonasa_p2 = .
replace svs_fonasa_p2 = 1 if svs_p == 0 & fonasa == 1 // sin seguro con fonasa
replace svs_fonasa_p2 = 3 if svs_p == 1 & fonasa == 1 // con seguro con fonasa
replace svs_fonasa_p2 = 2 if svs_p == 0 & fonasa == 0 // sin seguro con isapre
replace svs_fonasa_p2 = 4 if svs_p == 1 & fonasa == 0 // con seguro con isapre

preserve
collapse (sum) x [fw=expr], by(svs_fonasa_p2 grupo_edad)
bysort grupo_edad: egen total = total(x)
gen edad = (x/total)*100

reshape wide total x edad, i(grupo_edad) j(svs_fonasa_p2)
gen A = edad1
gen B = edad1 + edad2 
gen C = edad1 + edad2 + edad3
gen D = edad1 + edad2 + edad3 + edad4

twoway (bar A grupo_edad, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B grupo_edad, bcolor(emidblue*0.4) barwidth(0.8)) /// 
	   (rbar B C grupo_edad, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (rbar C D grupo_edad, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter A grupo_edad, mlabel(edad1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B grupo_edad, mlabel(edad2) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter C grupo_edad, mlabel(edad3) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter D grupo_edad, mlabel(edad4) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) xlabel(1 "< 18 " 2 "[18-25[" 3 "[25-35[" 4 "[35-45[" 5 "[45-55[" 6 "[55-65[" 7 "[65-75[" 8 "> 75", angle(0)) /// 
	   legend(order(1 2 3 4) label(1 "Sin SVS; FONASA") label(2 "Sin SVS; ISAPRE") label(3 "Con SVS; FONASA") label(4 "Con SVS; ISAPRE") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) name(x1, replace)  /// 
	   scale(.6) xtitle("Años de edad") 
restore

/* Gráfico combinación previsión y SVS a nivel de persona, según quintiles de ingreso */
preserve
collapse (sum) x [fw=expr], by(svs_fonasa_p qaut)
bysort qaut: egen total = total(x)
gen quintil = (x/total)*100

reshape wide total x quintil, i(qaut) j(svs_fonasa_p)
gen A = quintil1
gen B = quintil1 + quintil2 
gen C = quintil1 + quintil2 + quintil3
gen D = quintil1 + quintil2 + quintil3 + quintil4

twoway (bar A qaut, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B qaut, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (rbar B C qaut, bcolor(emidblue*0.4) barwidth(0.8)) /// 
	   (rbar C D qaut, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter A qaut, mlabel(quintil1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B qaut, mlabel(quintil2) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter C qaut, mlabel(quintil3) msymbol(i) mlabposition(10) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter D qaut, mlabel(quintil4) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) xlabel(1 "I" 2 "II" 3 "III" 4 "IV" 5 "V", angle(0)) /// 
	   legend(order(1 2 3 4) label(1 "Sin SVS; FONASA") label(2 "Con SVS; FONASA") label(3 "Sin SVS; ISAPRE") label(4 "Con SVS; ISAPRE") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white))  name(x1, replace)  /// 
	   scale(.6) xtitle("Quntil de ingreso per cápita")
restore


/* Gráficos a nivel de núcleo familiar */

/* Edad jefatura de núcleo */
graph bar edad [aweight = expr], over(svs_fonasa, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ylabel(0(10)60, angle(0)) ytitle("Promedio edad") name(g1, replace) title("Edad jefatura de núcleo")

/* Sexo jefatura de núcleo */
graph bar mujer [aweight = expr], over(svs_fonasa, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ytitle("Proporción mujeres") name(g2, replace) title("Sexo jefatura de núcleo")

/* Tamaño de núcleo */
graph bar tot_nucleo [aweight = expr], over(svs_fonasa, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ytitle("Promedio integrantes") name(g3, replace) title("Tamaño núcleo familiar")

/* Ocupación jefatura de núcleo */
graph bar empleo [aweight = expr], over(svs_fonasa, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ytitle("Proporción ocupación") name(g4, replace) title("Ocupación jefatura de núcleo")

/* Ingreso per cápita */
graph bar ingreso_pc_miles [aweight = expr], over(svs_fonasa, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ytitle("Promedio ingreso (miles de CLP)") name(g5, replace) title("Ingreso per cápita")

/* Zona */
graph bar urbano [aweight = expr], over(svs_fonasa, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ytitle("Proporción zona urbana") name(g6, replace) title("Zona")

graph combine g1 g2 g3 g4 g5 g6
 
 
/* Acceso a salud */
 
/*"Luego de un problema de salud, enfermedad o accidente, ¿Tuvo consulta o atención médica?"*/

preserve
drop if s17 == . | s17 == -88
gen acceso = 1 if s17 == 1
replace acceso = 0 if s17 == 2
collapse (sum) x [fw=expr], by(svs_fonasa_p acceso)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100

reshape wide total x cond, i(svs_fonasa_p) j(acceso)
gen A = cond0
gen B = cond0 + cond1 

twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Luego de un problema de salud, enfermedad o accidente," "¿Tuvo consulta o atención médica?") ///
	   name(x1, replace)  scale(.6) xtitle("")
restore

/* En quienes no consultaron: Pensó consultar pero no tuvo dinero*/
replace s18 = . if s18 == -88
tab s18, gen (s18r)
tab svs_fonasa_p s18r9 [fw = expr], row nofreq matcell(svs_fonasa_p)
gen s18r9_c=s18r9*100
graph bar s18r9_c [fweight = expr], blabel(bar, format(%9.1f)) over(svs_fonasa_p, label(angle(45)) relabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE")) bar(1, color(teal)) ylabel(0(1)4, angle(0)) ytitle("Porcentaje") title("Pensó en consultar pero no tuvo dinero")

/* En quienes sí consultaron: tuvieron problemas con el pago*/
gen prob_pago = .
replace prob_pago = 0 if s19d == 2
replace prob_pago = 1 if s19d == 1
preserve
drop if prob_pago == .
collapse (sum) x [fw=expr], by(svs_fonasa_p prob_pago)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(prob_pago)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("¿Tuvo problemas con el pago de la atención de salud recibida" "por el problema de salud, enfermedad o accidente de los últimos 3 meses?") ///
	   name(x1, replace)  scale(.6) xtitle("")
restore

/* Papanicolau */
gen pap = . 
replace pap = 0 if s9a == 2 
replace pap = 1 if s9a == 1 

preserve
drop if pap == .
collapse (sum) x [fw=expr], by(svs_fonasa_p pap)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(pap)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") position(6) rows(1)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Papanicolau en últimos 3 años") ///
	   name(g1, replace)  scale(.6) xtitle("")
restore

/* Mamografía */
gen mam = . 
replace mam = 0 if s11a == 2
replace mam = 1 if s11a == 1

preserve
drop if mam == .
collapse (sum) x [fw=expr], by(svs_fonasa_p mam)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(mam)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") position(6) rows(1)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Mamografía en últimos 3 años") ///
	   name(g2, replace)  scale(.6) xtitle("")
restore
	   
/* Exámenes de laboratorio */
gen examen_lab = .
replace examen_lab = 0 if s25a1_preg == 2
replace examen_lab = 1 if s25a1_preg == 1

preserve
drop if examen_lab == .
collapse (sum) x [fw=expr], by(svs_fonasa_p examen_lab)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(examen_lab)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6) ) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Exámenes de laboratorio en últimos 3 meses") ///
	   name(g3, replace)  scale(.6) xtitle("")
restore

/* Imágenes */
gen examen_imag = .
replace examen_imag = 0 if s25a2_preg == 2
replace examen_imag = 1 if s25a2_preg == 1

preserve
drop if examen_imag == .
collapse (sum) x [fw=expr], by(svs_fonasa_p examen_imag)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(examen_imag)
gen A = cond0
gen B = cond0 + cond1 

twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Exámenes de rayos X o ecografías en últimos 3 meses") ///
	   name(g4, replace)  scale(.6) xtitle("")
restore

graph combine g1 g2 g3 g4, graphregion(fcolor(white))

/* Medicina general */
gen med_gen = .
replace med_gen = 0 if s20a_preg == 2
replace med_gen = 1 if s20a_preg == 1
preserve
drop if med_gen == .
collapse (sum) x [fw=expr], by(svs_fonasa_p med_gen)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(med_gen)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Medicina general") ///
	   name(g1, replace)  scale(.6) xtitle("")
restore

/* Urgencia */
gen urgencia = .
replace urgencia = 0 if s21a_preg == 2
replace urgencia = 1 if s21a_preg == 1
preserve
drop if urgencia == .
collapse (sum) x [fw=expr], by(svs_fonasa_p urgencia)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(urgencia)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Urgencias") ///
	   name(g2, replace)  scale(.6) xtitle("")
restore

/* Salud mental */
gen med_mental = .
replace med_mental = 0 if s22a_preg == 2
replace med_mental = 1 if s22a_preg == 1
preserve
drop if med_mental == .
collapse (sum) x [fw=expr], by(svs_fonasa_p med_mental)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(med_mental)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Salud mental") ///
	   name(g3, replace)  scale(.6) xtitle("")
restore

/* Especialidad */
gen med_esp = .
replace med_esp = 0 if s23a_preg == 2
replace med_esp = 1 if s23a_preg == 1
preserve
drop if med_esp == .
collapse (sum) x [fw=expr], by(svs_fonasa_p med_esp)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(med_esp)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") position(6) rows(1)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Especialidad") ///
	   name(g4, replace)  scale(.6) xtitle("")
restore

graph combine g1 g2 g3 g4, graphregion(fcolor(white))


/*Número promedio de consultas por tipo de atención*/

/* Medicina general*/
preserve
replace s20a = . if s20a == -88
mean s20a [aw = expr], over(svs_fonasa_p)
collapse (mean) s20a (sd) sd=s20a (count) n=s20a [aw=expr], by(svs_fonasa_p)
gen hi_s20a = s20a + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_s20a = s20a - invttail(n-1,0.025)*(sd/sqrt(n))
twoway (bar s20a svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar s20a svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar s20a svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar s20a svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter s20a svs_fonasa_p, mlabel(s20a) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_s20a lo_s20a svs_fonasa_p, color(gray)) ///
	   ,  ylabel(0(0.25)2, format(%5.2f) angle(0) ) ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Promedio atenciones") graphregion(fcolor(white)) title("Medicina general")  name(g1, replace)  scale(.6) xtitle("") legend(off)
restore

/* Urgencias */
preserve
replace s21a = . if s21a == -88
mean s21a [aw = expr], over(svs_fonasa_p)
collapse (mean) s21a (sd) sd=s21a (count) n=s21a [aw=expr], by(svs_fonasa_p)
gen hi_s21a = s21a + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_s21a = s21a - invttail(n-1,0.025)*(sd/sqrt(n))
twoway (bar s21a svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar s21a svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar s21a svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar s21a svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter s21a svs_fonasa_p, mlabel(s21a) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_s21a lo_s21a svs_fonasa_p, color(gray)) ///
	   ,  ylabel(0(0.25)2, format(%5.2f) angle(0) ) ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Promedio atenciones") graphregion(fcolor(white)) title("Urgencias")  name(g2, replace)  scale(.6) xtitle("") legend(off)
restore

/* Salud mental */
preserve
replace s22a = . if s22a == -88
mean s22a [aw = expr], over(svs_fonasa_p)
collapse (mean) s22a (sd) sd=s22a (count) n=s22a [aw=expr], by(svs_fonasa_p)
gen hi_s22a = s22a + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_s22a = s22a - invttail(n-1,0.025)*(sd/sqrt(n))
twoway (bar s22a svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar s22a svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar s22a svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar s22a svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter s22a svs_fonasa_p, mlabel(s22a) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_s22a lo_s22a svs_fonasa_p, color(gray)) ///
	   ,  ylabel(0(0.5)5.5, format(%5.2f) angle(0) ) ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Promedio atenciones") graphregion(fcolor(white)) title("Salud mental")  name(g3, replace)  scale(.6) xtitle("") legend(off)
restore

/* Especialidad */
preserve
replace s23a = . if s23a == -88
mean s23a [aw = expr], over(svs_fonasa_p)
collapse (mean) s23a (sd) sd=s23a (count) n=s23a [aw=expr], by(svs_fonasa_p)
gen hi_s23a = s23a + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_s23a = s23a - invttail(n-1,0.025)*(sd/sqrt(n))
twoway (bar s23a svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar s23a svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar s23a svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar s23a svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter s23a svs_fonasa_p, mlabel(s23a) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_s23a lo_s23a svs_fonasa_p, color(gray)) ///
	   ,  ylabel(0(0.25)2.5, format(%5.2f) angle(0) ) ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Promedio atenciones") graphregion(fcolor(white)) title("Especialidad")  name(g4, replace)  scale(.6) xtitle("") legend(off)
restore

graph combine g1 g2 g3 g4, graphregion(fcolor(white))

/* Salud dental */
/* Acceso */
gen dental = .
replace dental = 0 if s24a_preg == 2
replace dental = 1 if s24a_preg == 1
preserve
drop if dental == .
collapse (sum) x [fw=expr], by(svs_fonasa_p dental)
bysort svs_fonasa_p : egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(dental)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p , bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Atención o consulta dental en últimos 3 meses") ///
	   name(g1, replace)  scale(.6) xtitle("")
restore

/* Promedio atenciones¨*/
preserve
replace s24a = . if s24a == -88
mean s24a [aw = expr], over(svs_fonasa_p)
collapse (mean) s24a (sd) sd=s24a (count) n=s24a [aw=expr], by(svs_fonasa_p)
gen hi_s24a = s24a + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_s24a = s24a - invttail(n-1,0.025)*(sd/sqrt(n))
twoway (bar s24a svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar s24a svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar s24a svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar s24a svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter s24a svs_fonasa_p, mlabel(s24a) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_s24a lo_s24a svs_fonasa_p, color(gray)) ///
	   ,  ylabel(0(0.25)3, format(%5.2f) angle(0) ) ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Promedio atenciones") graphregion(fcolor(white)) title("Promedio de atenciones dentales en últimos 3 meses")  name(g2, replace)  scale(.6) xtitle("") legend(off)
restore

/* Controles de salud*/
/*Acceso*/
gen control = .
replace control = 0 if s26a == 0
replace control = 1 if s26a >= 1 & s26a < .
preserve
drop if control == .
collapse (sum) x [fw=expr], by(svs_fonasa_p control)
bysort svs_fonasa_p: egen total = total(x)
gen cond = (x/total)*100
reshape wide total x cond, i(svs_fonasa_p) j(control)
gen A = cond0
gen B = cond0 + cond1 
twoway (bar A svs_fonasa_p, bcolor(teal*0.4) barwidth(0.8)) /// 
	   (rbar A B svs_fonasa_p, bcolor(teal*0.8) barwidth(0.8)) /// 
	   (scatter A svs_fonasa_p, mlabel(cond0) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (scatter B svs_fonasa_p, mlabel(cond1) msymbol(i) mlabposition(6) mlabformat(%5.2f) mlabcolor(black)), /// 
	   ylabel(0(20)100, angle(0)) /// 
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   legend(order(1 2) label(1 "No") label(2 "Sí") rows(1) position(6)) /// 
	   ytitle("Porcentaje") graphregion(fcolor(white)) title("Control de salud en último año") ///
	   name(g3, replace)  scale(.6) xtitle("")
restore

/* Promedio atenciones */
preserve
replace s26a = . if s26a == -88
mean s26a [aw = expr], over(svs_fonasa_p)
collapse (mean) s26a (sd) sd=s26a (count) n=s26a [aw=expr], by(svs_fonasa_p)
gen hi_s26a = s26a + invttail(n-1,0.025)*(sd/sqrt(n))
gen lo_s26a = s26a - invttail(n-1,0.025)*(sd/sqrt(n))
twoway (bar s26a svs_fonasa_p if svs_fonasa_p == 1, bcolor(teal*0.4) barwidth(0.8)) ///
	   (bar s26a svs_fonasa_p if svs_fonasa_p == 2, bcolor(teal*0.8) barwidth(0.8)) ///
	   (bar s26a svs_fonasa_p if svs_fonasa_p == 3, bcolor(emidblue*0.4) barwidth(0.8)) ///
	   (bar s26a svs_fonasa_p if svs_fonasa_p == 4, bcolor(emidblue*0.8) barwidth(0.8)) ///
	   (scatter s26a svs_fonasa_p, mlabel(s26a) msymbol(i) mlabposition(2) mlabformat(%5.2f) mlabcolor(black)) /// 
	   (rcap hi_s26a lo_s26a svs_fonasa_p, color(gray)) ///
	   ,  ylabel(0(0.25)2.25, format(%5.2f) angle(0) ) ///
	   xlabel(1 "Sin SVS; FONASA" 2 "Con SVS; FONASA" 3 "Sin SVS; ISAPRE" 4 "Con SVS; ISAPRE", angle(0) labsize(small)) /// 
	   ytitle("Promedio atenciones") graphregion(fcolor(white)) title("Promedio de controles de salud en el último año")  name(g4, replace)  scale(.6) xtitle("") legend(off)
restore

graph combine g1 g3 g2 g4, graphregion(fcolor(white))