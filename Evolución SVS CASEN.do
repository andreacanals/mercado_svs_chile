/*CASEN 2022*/

// Importar base de datos CASEN 2022 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2022/Base%20de%20datos%20Casen%202022%20STATA_18%20marzo%202024.dta.zip

/*Identificador núcleo*/
tostring folio, gen(folio_s) format("%13.0f")
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/*SVS a nivel de jefaturas de núcleo y a nivel de personas*/
gen svs=.
replace svs=1 if s15==1
replace svs=0 if s15==2

bysort id_nucleo: egen svs_n = max(svs)

/*Estimación % de personas que viven en hogares con SVS*/
svyset varunit [w=expr], psu(varunit) strata(varstrat) singleunit(certainty)

svy: prop svs_n
svy: prop svs_n, over(region)

/*Previsión*/
gen prevision = .
replace prevision = 1 if s13 == 1 // fonasa 
replace prevision = 2 if s13 == 2 // isapre
label define prevision 1 "FONASA" 2 "ISAPRE"
label values prevision prevision
tab s13 prevision

/*Estimación % de personas que viven en hogares con SVS, sólo FONASA e Isapre*/
svy, subpop(if prevision!=.): prop svs_n
svy, subpop(if prevision!=.): prop svs_n, over(region)


/*CASEN 2020*/

// Importar base de datos CASEN 2020 en formato dta, disponible en:
//https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2020/Casen_en_Pandemia_2020_STATA_revisada2022_09.dta.zip

// Fusionar con base de datos con factores de expansión actualizados con metodología CASEN 2022 disponible en:
//https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2020/Casen2020_factor_raking_deciles_y_quintil%20STATA.dta.zip

// Para fusionar utilizar código:
// merge 1:1 folio id_persona using "Casen2020_factor_raking_deciles_y_quintil STATA.dta"

/*Identificador núcleo*/
tostring folio, gen(folio_s) format("%13.0f")
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/*SVS a nivel de jef@s de núcleo y a nivel de personas*/
gen svs=.
replace svs=1 if s15==1
replace svs=0 if s15==2
bysort id_nucleo: egen svs_n = max(svs)

/*Estimación % de personas que viven en hogares con SVS*/
tab svs_n
svyset varunit [w=expr], psu(varunit) strata(varstrat) singleunit(certainty)
svy: prop svs_n
svy: prop svs_n, over(region)

/*Previsión*/
gen prevision = .
replace prevision = 1 if s13 == 1 // fonasa 
replace prevision = 2 if s13 == 3 // isapre
label define prevision 1 "FONASA" 2 "ISAPRE"
label values prevision prevision
tab s13 prevision

/*Estimación % de personas que viven en hogares con SVS, sólo FONASA e Isapre*/
svy, subpop(if prevision!=.): prop svs_n
svy, subpop(if prevision!=.): prop svs_n, over(region)


/*CASEN 2017*/

// Importar base de datos CASEN 2017 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2017/casen_2017_stata.rar

// Fusionar con base de datos con factores de expansión actualizados con metodología CASEN 2022 disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2017/Casen2017_factor_raking_deciles_y_quintil%20STATA.dta.zip

// Para fusionar utilizar código:
// merge 1:1 folio id_persona using "Casen2017_factor_raking_deciles_y_quintil STATA.dta"

/*Identificador núcleo*/
tostring folio, gen(folio_s) format("%13.0f")
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/*SVS a nivel de jef@s de núcleo y a nivel de personas*/
gen svs=.
replace svs=1 if s14==1
replace svs=0 if s14==2
bysort id_nucleo: egen svs_n = max(svs)

/*Estimación % de personas que viven en hogares con SVS*/
tab svs_n
svyset varunit [w=expr], psu(varunit) strata(varstrat) singleunit(certainty)
svy: prop svs_n
svy: prop svs_n, over(region)

/*Previsión*/
gen prevision = .
replace prevision = 1 if s12 == 1 | s12 ==2 | s12 ==3 | s12 == 4 | s12 == 5 // fonasa 
replace prevision = 2 if s12 == 7 // isapre
label define prevision 1 "FONASA" 2 "ISAPRE"
label values prevision prevision
tab s12 prevision

/*Estimación % de personas que viven en hogares con SVS, sólo FONASA e Isapre*/
svy, subpop(if prevision!=.): prop svs_n
svy, subpop(if prevision!=.): prop svs_n, over(region)


/*CASEN 2015*/

// Importar base de datos CASEN 2015 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2015/casen_2015_stata.rar

// Fusionar con base de datos con factores de expansión actualizados con metodología CASEN 2022 disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2015/Casen2015_factor_raking_deciles_y_quintil%20STATA.dta.zip

// Para fusionar utilizar código:
// merge 1:1 folio id_persona using "Casen2015_factor_raking_deciles_y_quintil STATA.dta"

/*Identificador núcleo*/
tostring folio, gen(folio_s) format("%13.0f")
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/*SVS a nivel de jef@s de núcleo y a nivel de personas*/
gen svs=.
replace svs=1 if s14==1
replace svs=0 if s14==2
bysort id_nucleo: egen svs_n = max(svs)

/*Estimación % de personas que viven en hogares con SVS*/
tab svs_n
svyset varunit [w=expr], psu(varunit) strata(varstrat) singleunit(certainty)
svy: prop svs_n
svy: prop svs_n, over(region)

/*Previsión*/
gen prevision = .
replace prevision = 1 if s12 == 1 | s12 ==2 | s12 ==3 | s12 == 4 | s12 == 5 // fonasa 
replace prevision = 2 if s12 == 7 // isapre
label define prevision 1 "FONASA" 2 "ISAPRE"
label values prevision prevision
tab s12 prevision

/*Estimación % de personas que viven en hogares con SVS, sólo FONASA e Isapre*/
svy, subpop(if prevision!=.): prop svs_n
svy, subpop(if prevision!=.): prop svs_n, over(region)


/*CASEN 2013*/

// Importar base de datos CASEN 2013 en formato dta, disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2013/casen_2013_mn_b_principal_stata.rar

// Fusionar con base de datos con factores de expansión actualizados con metodología CASEN 2022 disponible en:
// https://observatorio.ministeriodesarrollosocial.gob.cl/storage/docs/casen/2013/Casen2013_factor_raking_deciles_y_quintil%20STATA.dta.zip

// Para fusionar utilizar código:
// merge 1:1 folio id_persona using "Casen2013_factor_raking_deciles_y_quintil STATA.dta"

/*Identificador núcleo*/
tostring folio, gen(folio_s) format("%13.0f")
tostring nucleo, gen(nucleo_s)
egen id_nucleo = concat(folio_s nucleo_s), punct(-)

/*SVS a nivel de jef@s de núcleo y a nivel de personas*/
gen svs=.
replace svs=1 if s15a==1
replace svs=0 if s15a==2
bysort id_nucleo: egen svs_n = max(svs)

/*Estimación % de personas que viven en hogares con SVS*/
tab svs_n
svyset varunit [w=expr], psu(varunit) strata(varstrat) singleunit(certainty)
svy: prop svs_n
svy: prop svs_n, over(region)

/*Previsión*/
gen prevision = .
replace prevision = 1 if s14 == 1 | s14 ==2 | s14 ==3 | s14 == 4 | s14 == 5 // fonasa 
replace prevision = 2 if s14 == 7 // isapre
label define prevision 1 "FONASA" 2 "ISAPRE"
label values prevision prevision
tab s14 prevision

/*Estimación % de personas que viven en hogares con SVS, sólo FONASA e Isapre*/
svy, subpop(if prevision!=.): prop svs_n
svy, subpop(if prevision!=.): prop svs_n, over(region)

// Las estimaciones obtenidas por año y región se guardaron en el archivo "Estimaciones SVS por año y región.xlsx"

/*Gráfico evolución %SVS*/

// Importar hoja "AÑO" de base de datos "Estimaciones SVS por año y región.xlsx"
// Para importar usar código:
// import excel "Estimaciones SVS por año y región.xlsx", sheet("AÑO") firstrow case(lower) clear

replace svs=round(svs, 0.01)
replace svs_li=round(svs_li, 0.01)
replace svs_ls=round(svs_ls, 0.01)

twoway (line svs año, mlabel(svs) ytitle("% SVS") xtitle("Año") ylabel(0(2)20, angle(0)) xlabel(2012(1)2023, angle(0)) lcolor(blue)) (scatter svs año, ms(none) mlabel(svs) mlabposition(12) mlabgap(4)) (line svs_li año, lcolor(ltblue) lpattern(dash)) (line svs_ls año, lcolor(eltgreen) lpattern(dash)), legend(order(1 "Estimación puntual" 2 "Límite inferior IC 95%" 3 "Límite superior IC 95%") position(6) cols(3))


/*Gráfico evolución %SVS por region*/

// Importar hoja "AÑO Y REGION" de base de datos "Estimaciones SVS por año y región.xlsx"
// Para importar usar código:
// import excel "Estimaciones SVS por año y región.xlsx", sheet("AÑO Y REGION") firstrow case(lower) clear

reshape long a, i(region) j(año)
drop if a==.
rename a svs

label define region 1 "Tarapacá" 2 "Antofagasta" 3 "Atacama" 4 "Coquimbo" 5 "Valparaíso" 6 "O'Higgins" 7 "Maule" 8 "Biobío" 9 "Araucanía" 10 "Los Lagos" 11 "Aysén" 12 "Magallanes" 13 "Metropolitana" 14 "Los Ríos" 15 "Arica y Parinacota" 16 "Ñuble"
label values region region

twoway (line svs año, mlabel(svs) ytitle("% SVS") xtitle("Año") ylabel(0(5)20, angle(0)) by(region, note("")) xlabel(2013 2015 2017 2020 2022, angle(0)) lcolor(blue)) 