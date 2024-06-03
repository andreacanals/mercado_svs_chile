
/* CONSTRUCCIÓN BASE DE DATOS CASEN 2013 Y 2022*/

/* CASEN 2013 */

// Importar base de datos CASEN 2013 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2013/casen_2013_mn_b_principal_stata.rar

// Fusionar con base de datos con factores de expansión actualizados con metodología CASEN 2022 disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2013/Casen2013_factor_raking_deciles_y_quintil%20STATA.dta.zip

// Para fusionar utilizar código:
// merge 1:1 folio id_persona using "Casen2013_factor_raking_deciles_y_quintil STATA.dta"

/* Creación variables */

/* Identificador núcleo */
format folio %12.0f
tostring folio, gen(folio_s) format("%12.0f")
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/* SVS a nivel de núcleo y de persona */
/* svs -> Indica si alguien en el núcleo tiene svs */
gen svs = .
replace svs = 1 if s15a == 1
replace svs = 0 if s15a == 2
/* svs_p -> Indica si la persona vive en un núcleo en el que alguien tiene SVS */
bysort id_nucleo: egen svs_p = max(svs)

/* Previsión (0=ISAPRE, 1=ISAPRE)*/
gen fonasa = .
replace fonasa = 1 if s14 == 1 | s14 == 2 | s14 == 3 | s14 == 4 | s14 == 5
replace fonasa = 0 if s14 == 7

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
replace urbano = 1 if zona == 1

/*Ingresos (usando Ingreso Autónomo Corregido) */
clonevar yautcor2 = yautcor
replace yautcor2 = 0 if yautcor2 == .
gen yautcor3 = (yautcor2/22980.899)*33047.142 // ajuste por inflación a valores casen 2022 (dividiendo por promedio uf 2013 y multiplicando por promedio uf 2022)
gen yautcor3_miles=yautcor3/1000
gen x = 1
bysort id_nucleo: egen tot_nucleo = total(x) 
bysort id_nucleo: egen ingresos_tot = total(yautcor3)
bysort id_nucleo: egen ingresos_tot_miles = total(yautcor3_miles)
gen ingreso_pc = ingresos_tot/tot_nucleo
gen ingreso_pc_miles = ingresos_tot_miles/tot_nucleo

/*"Luego de un problema de salud, enfermedad o accidente, ¿Tuvo consulta o atención médica?"*/
gen acceso = 1 
replace acceso = 0 if s17 == 5
replace acceso = . if s17 == 9
replace acceso = . if s17 == .

/* Papanicolau */
gen pap = 1 
replace pap = . if s10 == 9 
replace pap = 0 if s10 == 4 

/* Mamografía */
gen mam = 1 
replace mam = . if s12 == 9 
replace mam = 0 if s12 == 4 
	   
/* Exámenes de laboratorio */
gen examen_lab = 1
replace examen_lab = 0 if s27a == 0
replace examen_lab = . if s27a == 99

/* Imágenes */
gen examen_imag = 1
replace examen_imag = 0 if s28a == 0
replace examen_imag = . if s28a == 99

/* Medicina general */
gen med_gen = 1
replace med_gen = 0 if s22a == 0
replace med_gen = . if s22a == 99

/* Urgencia */
gen urgencia = 1
replace urgencia = 0 if s23a == 0
replace urgencia = . if s23a == 99

/* Salud mental */
gen med_mental = 1
replace med_mental = 0 if s24a == 0
replace med_mental = . if s24a == 99

/* Especialidad */
gen med_esp = 1
replace med_esp = 0 if s25a == 0
replace med_esp = . if s25a == 99

/* Salud dental */
gen dental = 1
replace dental = 0 if s26a == 0
replace dental = . if s26a == 99

/* Controles de salud*/
gen control = 1
replace control = 0 if s29a == 0
replace control = . if s29a == 99

/*Número de consultas por tipo de atención*/

/* Medicina general*/
gen n_consultas_medgen=s22a
replace n_consultas_medgen = . if s22a == 99

/* Urgencias */
gen n_consultas_urg=s23a
replace n_consultas_urg = . if s23a == 99

/* Salud mental */
gen n_consultas_sm=s24a
replace n_consultas_sm = . if s24a == 99

/* Especialidad */
gen n_consultas_esp=s25a
replace n_consultas_esp = . if s25a == 99

/* Salud dental*/
gen n_consultas_d=s26a
replace n_consultas_d = . if s26a == 99

/* Controles de salud */
gen n_controles=s29a
replace n_controles = . if s29a == 99

/* Filtramos sólo las personas que tienen fonasa e isapre*/
keep if svs_fonasa_p != .

/* Filtramos variables de interés */
gen año=2013
rename qaut_mn qaut
keep año folio folio_s o nucleo nucleo_s pco2 id_nucleo expr svs svs_p fonasa svs_fonasa svs_fonasa_p grupo_edad edad mujer empleo urbano tot_nucleo ingresos_tot ingresos_tot_miles ingreso_pc ingreso_pc_miles qaut acceso pap mam examen_lab examen_imag med_gen urgencia med_mental med_esp dental control n_consultas_medgen n_consultas_urg n_consultas_sm n_consultas_esp n_consultas_d n_controles varunit varstrat

// Guardar base de datos en formato dta usando código:
// save "CASEN 2013 editada.dta"


/* CASEN 2022 */

// Importar base de datos CASEN 2022 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2022/Base%20de%20datos%20Casen%202022%20STATA_18%20marzo%202024.dta.zip

/* Creación variables */

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

/* Previsión (0=ISAPRE, 1=ISAPRE)*/
gen fonasa = .
replace fonasa = 1 if s13 == 1
replace fonasa = 0 if s13 == 2

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

/*"Luego de un problema de salud, enfermedad o accidente, ¿Tuvo consulta o atención médica?"*/
gen acceso = 1 if s17 == 1
replace acceso = 0 if s17 == 2

/* Papanicolau */
gen pap = . 
replace pap = 0 if s9a == 2 
replace pap = 1 if s9a == 1 

/* Mamografía */
gen mam = . 
replace mam = 0 if s11a == 2
replace mam = 1 if s11a == 1
	   
/* Exámenes de laboratorio */
gen examen_lab = .
replace examen_lab = 0 if s25a1_preg == 2
replace examen_lab = 1 if s25a1_preg == 1

/* Imágenes */
gen examen_imag = .
replace examen_imag = 0 if s25a2_preg == 2
replace examen_imag = 1 if s25a2_preg == 1

/* Medicina general */
gen med_gen = .
replace med_gen = 0 if s20a_preg == 2
replace med_gen = 1 if s20a_preg == 1

/* Urgencia */
gen urgencia = .
replace urgencia = 0 if s21a_preg == 2
replace urgencia = 1 if s21a_preg == 1

/* Salud mental */
gen med_mental = .
replace med_mental = 0 if s22a_preg == 2
replace med_mental = 1 if s22a_preg == 1

/* Especialidad */
gen med_esp = .
replace med_esp = 0 if s23a_preg == 2
replace med_esp = 1 if s23a_preg == 1

/* Salud dental */
gen dental = .
replace dental = 0 if s24a_preg == 2
replace dental = 1 if s24a_preg == 1

/* Controles de salud*/
gen control = .
replace control = 0 if s26a == 0
replace control = 1 if s26a >= 1 & s26a < .

/*Número de consultas por tipo de atención*/

/* Medicina general*/
gen n_consultas_medgen=s20a
replace n_consultas_medgen = . if s20a == -88

/* Urgencias */
gen n_consultas_urg=s21a
replace n_consultas_urg = . if s21a == -88

/* Salud mental */
gen n_consultas_sm=s22a
replace n_consultas_sm = . if s22a == -88

/* Especialidad */
gen n_consultas_esp=s23a
replace n_consultas_esp = . if s23a == -88

/* Salud dental*/
gen n_consultas_d=s24a
replace n_consultas_d = . if s24a == -88

/* Controles de salud */
gen n_controles=s26a
replace n_controles = . if s26a == -88

/* Filtramos sólo las personas que tienen fonasa e isapre*/
keep if svs_fonasa_p != .

/* Filtramos variables de interés */
gen año=2022
keep año folio folio_s id_vivienda id_persona nucleo nucleo_s pco2 id_nucleo expr svs svs_p fonasa svs_fonasa svs_fonasa_p grupo_edad edad mujer empleo urbano tot_nucleo ingresos_tot ingresos_tot_miles ingreso_pc ingreso_pc_miles qaut acceso pap mam examen_lab examen_imag med_gen urgencia med_mental med_esp dental control n_consultas_medgen n_consultas_urg n_consultas_sm n_consultas_esp n_consultas_d n_controles varunit varstrat

// Unir con base editada 2013, con el siguiente código:
// append using "CASEN 2013 editada.dta"


/* RESULTADOS */

/* Distribución personas según combinación svs y previsión, año 2013*/

tab svs_fonasa_p, gen(g)

svyset varunit [w=expr], psu(varunit) strata(varstrat) singleunit(certainty)

svy, subpop( if año==2013): prop g1
svy, subpop( if año==2013): prop g2
svy, subpop( if año==2013): prop g3
svy, subpop( if año==2013): prop g4

/* Distribución personas según combinación svs y previsión, año 2022*/

svy, subpop( if año==2022): prop g1
svy, subpop( if año==2022): prop g2
svy, subpop( if año==2022): prop g3
svy, subpop( if año==2022): prop g4

/* Distribución grupo de aseguramiento en salud según año y sexo*/

svy, subpop(if año==2022&mujer==1): prop svs_fonasa_p
svy, subpop(if año==2013&mujer==1): prop svs_fonasa_p
svy, subpop(if año==2022&mujer==0): prop svs_fonasa_p
svy, subpop(if año==2013&mujer==0): prop svs_fonasa_p

svy: tabulate svs_fonasa_p año if mujer==0, pearson
svy: tabulate svs_fonasa_p año if mujer==1, pearson

/* Distribución grupo de aseguramiento en salud según año y grupo etario*/

gen grupo_edad2=grupo_edad
recode grupo_edad2 (2=1) (3/6=2) (7/8=3)

svy, subpop(if año==2022&grupo_edad2==1): prop svs_fonasa_p
svy, subpop(if año==2013&grupo_edad2==1): prop svs_fonasa_p
svy, subpop(if año==2022&grupo_edad2==2): prop svs_fonasa_p
svy, subpop(if año==2013&grupo_edad2==2): prop svs_fonasa_p
svy, subpop(if año==2022&grupo_edad2==3): prop svs_fonasa_p
svy, subpop(if año==2013&grupo_edad2==3): prop svs_fonasa_p

svy: tabulate svs_fonasa_p año if grupo_edad2==1, pearson
svy: tabulate svs_fonasa_p año if grupo_edad2==2, pearson
svy: tabulate svs_fonasa_p año if grupo_edad2==3, pearson

/* Distribución grupo de aseguramiento en salud según año y quintiles*/

svy, subpop(if año==2022&qaut==1): prop svs_fonasa_p
svy, subpop(if año==2013&qaut==1): prop svs_fonasa_p
svy, subpop(if año==2022&qaut==2): prop svs_fonasa_p
svy, subpop(if año==2013&qaut==2): prop svs_fonasa_p
svy, subpop(if año==2022&qaut==3): prop svs_fonasa_p
svy, subpop(if año==2013&qaut==3): prop svs_fonasa_p
svy, subpop(if año==2022&qaut==4): prop svs_fonasa_p
svy, subpop(if año==2013&qaut==4): prop svs_fonasa_p
svy, subpop(if año==2022&qaut==5): prop svs_fonasa_p
svy, subpop(if año==2013&qaut==5): prop svs_fonasa_p

svy: tabulate svs_fonasa_p año if qaut==1, pearson
svy: tabulate svs_fonasa_p año if qaut==2, pearson
svy: tabulate svs_fonasa_p año if qaut==3, pearson
svy: tabulate svs_fonasa_p año if qaut==4, pearson
svy: tabulate svs_fonasa_p año if qaut==5, pearson

/* Promedio edad jefatura de núcleo según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&pco2==1&svs_fonasa_p==1): mean edad
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==2): mean edad
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==3): mean edad
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==4): mean edad
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==1): mean edad
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==2): mean edad
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==3): mean edad
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==4): mean edad

svy: regress edad i.año i.svs_fonasa_p if pco2==1

/* Promedio tamaño núcleo según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&pco2==1&svs_fonasa_p==1): mean tot_nucleo
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==2): mean tot_nucleo
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==3): mean tot_nucleo
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==4): mean tot_nucleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==1): mean tot_nucleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==2): mean tot_nucleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==3): mean tot_nucleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==4): mean tot_nucleo

svy: regress tot_nucleo i.año i.svs_fonasa_p if pco2==1

/* Promedio ingreso según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&pco2==1&svs_fonasa_p==1): mean ingreso_pc_miles
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==2): mean ingreso_pc_miles
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==3): mean ingreso_pc_miles
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==4): mean ingreso_pc_miles
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==1): mean ingreso_pc_miles
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==2): mean ingreso_pc_miles
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==3): mean ingreso_pc_miles
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==4): mean ingreso_pc_miles

svy: regress ingreso_pc_miles i.año i.svs_fonasa_p if pco2==1

/* Proporción mujeres según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&pco2==1&svs_fonasa_p==1): prop mujer
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==2): prop mujer
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==3): prop mujer
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==4): prop mujer
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==1): prop mujer
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==2): prop mujer
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==3): prop mujer
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==4): prop mujer

svy: logit mujer i.svs_fonasa_p i.año if pco2==1

/* Proporción jefaturas con empleo según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&pco2==1&svs_fonasa_p==1): prop empleo
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==2): prop empleo
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==3): prop empleo
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==4): prop empleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==1): prop empleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==2): prop empleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==3): prop empleo
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==4): prop empleo

svy: logit empleo i.svs_fonasa_p i.año if pco2==1

/* Proporción zona urbana con empleo según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&pco2==1&svs_fonasa_p==1): prop urbano
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==2): prop urbano
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==3): prop urbano
svy, subpop(if año==2022&pco2==1&svs_fonasa_p==4): prop urbano
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==1): prop urbano
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==2): prop urbano
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==3): prop urbano
svy, subpop(if año==2013&pco2==1&svs_fonasa_p==4): prop urbano

svy: logit urbano i.svs_fonasa_p i.año if pco2==1

/* Proporción pap según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop pap
svy, subpop(if año==2022&svs_fonasa_p==2): prop pap
svy, subpop(if año==2022&svs_fonasa_p==3): prop pap
svy, subpop(if año==2022&svs_fonasa_p==4): prop pap
svy, subpop(if año==2013&svs_fonasa_p==1): prop pap
svy, subpop(if año==2013&svs_fonasa_p==2): prop pap
svy, subpop(if año==2013&svs_fonasa_p==3): prop pap
svy, subpop(if año==2013&svs_fonasa_p==4): prop pap

svy: logit pap i.svs_fonasa_p i.año

/* Proporción mamografía según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop mam
svy, subpop(if año==2022&svs_fonasa_p==2): prop mam
svy, subpop(if año==2022&svs_fonasa_p==3): prop mam
svy, subpop(if año==2022&svs_fonasa_p==4): prop mam
svy, subpop(if año==2013&svs_fonasa_p==1): prop mam
svy, subpop(if año==2013&svs_fonasa_p==2): prop mam
svy, subpop(if año==2013&svs_fonasa_p==3): prop mam
svy, subpop(if año==2013&svs_fonasa_p==4): prop mam

svy: logit mam i.svs_fonasa_p i.año

/* Proporción exámenes de laboratorio según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop examen_lab
svy, subpop(if año==2022&svs_fonasa_p==2): prop examen_lab
svy, subpop(if año==2022&svs_fonasa_p==3): prop examen_lab
svy, subpop(if año==2022&svs_fonasa_p==4): prop examen_lab
svy, subpop(if año==2013&svs_fonasa_p==1): prop examen_lab
svy, subpop(if año==2013&svs_fonasa_p==2): prop examen_lab
svy, subpop(if año==2013&svs_fonasa_p==3): prop examen_lab
svy, subpop(if año==2013&svs_fonasa_p==4): prop examen_lab

svy: logit examen_lab i.svs_fonasa_p i.año

/* Proporción exámenes de rx o ecografía según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop examen_imag
svy, subpop(if año==2022&svs_fonasa_p==2): prop examen_imag
svy, subpop(if año==2022&svs_fonasa_p==3): prop examen_imag
svy, subpop(if año==2022&svs_fonasa_p==4): prop examen_imag
svy, subpop(if año==2013&svs_fonasa_p==1): prop examen_imag
svy, subpop(if año==2013&svs_fonasa_p==2): prop examen_imag
svy, subpop(if año==2013&svs_fonasa_p==3): prop examen_imag
svy, subpop(if año==2013&svs_fonasa_p==4): prop examen_imag

svy: logit examen_imag i.svs_fonasa_p i.año

/* Proporción consulta de medicina general según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop med_gen
svy, subpop(if año==2022&svs_fonasa_p==2): prop med_gen
svy, subpop(if año==2022&svs_fonasa_p==3): prop med_gen
svy, subpop(if año==2022&svs_fonasa_p==4): prop med_gen
svy, subpop(if año==2013&svs_fonasa_p==1): prop med_gen
svy, subpop(if año==2013&svs_fonasa_p==2): prop med_gen
svy, subpop(if año==2013&svs_fonasa_p==3): prop med_gen
svy, subpop(if año==2013&svs_fonasa_p==4): prop med_gen

svy: logit med_gen i.svs_fonasa_p i.año

/* Proporción consulta de urgencias según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop urgencia
svy, subpop(if año==2022&svs_fonasa_p==2): prop urgencia
svy, subpop(if año==2022&svs_fonasa_p==3): prop urgencia
svy, subpop(if año==2022&svs_fonasa_p==4): prop urgencia
svy, subpop(if año==2013&svs_fonasa_p==1): prop urgencia
svy, subpop(if año==2013&svs_fonasa_p==2): prop urgencia
svy, subpop(if año==2013&svs_fonasa_p==3): prop urgencia
svy, subpop(if año==2013&svs_fonasa_p==4): prop urgencia

svy: logit urgencia i.svs_fonasa_p i.año

/* Proporción consulta de salud mental según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop med_mental
svy, subpop(if año==2022&svs_fonasa_p==2): prop med_mental
svy, subpop(if año==2022&svs_fonasa_p==3): prop med_mental
svy, subpop(if año==2022&svs_fonasa_p==4): prop med_mental
svy, subpop(if año==2013&svs_fonasa_p==1): prop med_mental
svy, subpop(if año==2013&svs_fonasa_p==2): prop med_mental
svy, subpop(if año==2013&svs_fonasa_p==3): prop med_mental
svy, subpop(if año==2013&svs_fonasa_p==4): prop med_mental

svy: logit med_mental i.svs_fonasa_p i.año

/* Proporción consulta de especialidad según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop med_esp
svy, subpop(if año==2022&svs_fonasa_p==2): prop med_esp
svy, subpop(if año==2022&svs_fonasa_p==3): prop med_esp
svy, subpop(if año==2022&svs_fonasa_p==4): prop med_esp
svy, subpop(if año==2013&svs_fonasa_p==1): prop med_esp
svy, subpop(if año==2013&svs_fonasa_p==2): prop med_esp
svy, subpop(if año==2013&svs_fonasa_p==3): prop med_esp
svy, subpop(if año==2013&svs_fonasa_p==4): prop med_esp

svy: logit med_esp i.svs_fonasa_p i.año

/* Proporción consulta dental según grupo de aseguramiento en salud y año*/

svy, subpop(if año==2022&svs_fonasa_p==1): prop dental
svy, subpop(if año==2022&svs_fonasa_p==2): prop dental
svy, subpop(if año==2022&svs_fonasa_p==3): prop dental
svy, subpop(if año==2022&svs_fonasa_p==4): prop dental
svy, subpop(if año==2013&svs_fonasa_p==1): prop dental
svy, subpop(if año==2013&svs_fonasa_p==2): prop dental
svy, subpop(if año==2013&svs_fonasa_p==3): prop dental
svy, subpop(if año==2013&svs_fonasa_p==4): prop dental

svy: logit dental i.svs_fonasa_p i.año