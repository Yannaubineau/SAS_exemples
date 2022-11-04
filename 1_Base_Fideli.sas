*******************************************************************************
***** Programme - Base individus Fideli complète en France Métropolitaine *****
*******************************************************************************

Yann Aubineau
29/12/2020
Stage Ined
yann.r.aubineau@gmail.com;

/*
L'objectif de ce programme est de fusionner de façon raisonnée les 3 bases d'individus Fideli dans une seule base complète. Il sélectionne les variables qui seront utilisées dans les programmes ultérieurs,
créé directement des variables essentielles (âge,...) et identifie des populations particulières (enfants, personnes à charge) pour circonscrire le champ de mes recherches sur les couples cohabitant.
A l'issu de la récolte de ces informations, il réalise un output conditionné aux individus en France métropolitaine, présents en 2016 et en éliminant les double-compte.
*/

libname fideli "C:\Users\Public\Documents\Yann Aubineau\Logement_FIDELI_2017\Versions\V1"; 
libname verif  "C:\Users\Public\Documents\Yann Aubineau\Logement_FIDELI_2017\Verif";

data verif.base_ind_complet2017;
	set fideli.fideli_individu17_diff_1 
				(keep = type_fisc 
				type_fisc2016
				anais 
				id_log2016
				id_log
				id_foy
				id_foy2016
				lien_familial	
				lien_familial2016	
				situf_deb	
				situf_fin
				sexe	
				andec
				zoxyzd2
				dacoed2
				resid_anchang
				pres_ind
				biloc
				biloc2016
				csdep2016
				csdep
				reg)
		fideli.fideli_individu17_diff_2 	
				(keep = type_fisc 
				type_fisc2016
				anais 
				id_log2016
				id_log
				id_foy
				id_foy2016
				lien_familial	
				lien_familial2016	
				situf_deb	
				situf_fin
				sexe	
				andec
				zoxyzd2
				dacoed2
				resid_anchang
				pres_ind
				biloc
				biloc2016
				csdep2016
				csdep
				reg)
		fideli.fideli_individu17_diff_3
		(keep = type_fisc 
				type_fisc2016
				anais 
				id_log2016
				id_log
				id_foy
				id_foy2016
				lien_familial	
				lien_familial2016	
				situf_deb	
				situf_fin
				sexe	
				andec
				zoxyzd2
				dacoed2
				resid_anchang
				pres_ind
				biloc
				biloc2016
				csdep2016
				csdep
				reg);
	** Création de variables utiles pour analyses;
		*Âge en années révolues selon l'année considérée  (ATTENTION : dans le cadre de mes recherches, l'âge utilisé est age2016, toutes les variables catégorielles qui suivent sont construitent par rapport 
		 	à age2016);
	age2017 = 2016 - anais;
	age2016 = 2015 - anais;
		*Dichotomique mort;
	if andec ^= "" then mort = 1; else mort = 0;
		*Sexe recodé (ATTENTION : l'ensemble de la population de Fideli n'est pas codé 1 ou 2 (voir documentation), certaines personnes ainsi que les enfants n'ont pas leur sexe codé);
	if sexe = "1" then sexe_reco = "Homme";
	if sexe = "2" then sexe_reco = "Femme";
		* Information ID (Pour l'exploration de la base Fideli il peut être intéressant d'observer quelles informations possèdent les individus selon la présence ou non d'un identifiant logement,
	      particulièrement vrai pour l'étude des morts);
	length quel_id $ 8;
	if id_log = . and id_log2016 = . then quel_id = "0id"; 
	if id_log = . and id_log2016 ^= . then quel_id = "id2016";
 	if id_log ^= . and id_log2016 = . then quel_id = "id2017";
	if id_log ^= . and id_log2016 ^= . then quel_id = "2id";
		* Catégorie âge;
	if age2016 <= 14 then catage = "Moins ou égal à 14 ans";
	if age2016 >= 15 and age2016 <= 19 then catage = "15 à 19 ans";
	if age2016 >= 20 and age2016 <= 24 then catage = "20 à 24 ans";
	if age2016 >= 25 and age2016 <= 39 then catage = "25 à 39 ans";
	if age2016 >= 40 and age2016 <= 54 then catage = "40 à 54 ans";
	if age2016 >= 55 and age2016 <= 59 then catage = "55 à 59 ans";
	if age2016 >= 60 and age2016 <= 64 then catage = "60 à 64 ans";
	if age2016 >= 65 and age2016 <= 79 then catage = "65 à 79 ans";
	if age2016 >= 80 then catage = "80 ans ou plus";
		* Catégorie âge 5 par 5 ;
	if age2016 >= 18 and age2016 <= 24 then catage_5 = "18 à 24 ans";
	if age2016 >= 25 and age2016 <= 29 then catage_5 = "25 à 29 ans";
	if age2016 >= 30 and age2016 <= 34 then catage_5 = "30 à 34 ans";
	if age2016 >= 35 and age2016 <= 39 then catage_5 = "35 à 39 ans";
	if age2016 >= 40 and age2016 <= 44 then catage_5 = "40 à 44 ans";
	if age2016 >= 45 and age2016 <= 49 then catage_5 = "45 à 49 ans";
	if age2016 >= 50 and age2016 <= 54 then catage_5 = "50 à 54 ans";
	if age2016 >= 55 and age2016 <= 59 then catage_5 = "55 à 59 ans";
	if age2016 >= 60 and age2016 <= 64 then catage_5 = "60 à 64 ans";
	if age2016 >= 65 and age2016 <= 69 then catage_5 = "65 à 69 ans";
	if age2016 >= 70 and age2016 <= 74 then catage_5 = "70 à 74 ans";
	if age2016 >= 75 and age2016 <= 79 then catage_5 = "75 à 79 ans";
	if age2016 >= 80 then catage_5 = "80 ans ou plus";
		* Catégorie âge -55 ans / 55 - 85 / 85 - 100 +;
	if age2016 < 55 then catage_reco = "Moins de 55 ans";
	if age2016 >= 55 then catage_reco = "Plus de 55 ans";
		* Identification des enfants mineurs;
	if  type_fisc in ("A","B","C","D","E","F","G","I","J","a","b","c","d","e","f") and age2016 <= 18
		then enfant_mineur = 1; else enfant_mineur = 0;
	* Identification des personnes à charge (ATTENTION : dans cette codification, les enfants mineurs sont séparés des personnes à charge pour être étudiés séparément);
	if (type_fisc in ("03","04","05","06","07","08","09","10","A","B","C","D","E","F","G","I","J","a","b","c","d","e","f")
		or type_fisc2016 in ("3","4","5","6","7")) and age2016 > 18 
		then personne_charge = 1; else personne_charge = 0;
	* Personnes qui ne sont pas en couple cohabitant en 2016;
	if enfant_mineur = 1 or personne_charge = 1 then champ = 0; else champ = 1;
	* Condition d'apparition : être là 2 ans ou uniquement en 2017 (beaucoup ont des informations en 2016 malgré tout), être en France métropolitaine en 2016 (si pas info en 2016, être en métropole en 2017) et ne pas être un double-compte;
	if pres_ind in (2,3) and biloc in ("1","0","") and biloc2016 in (0,.) and
		(csdep2016 not in ("","97") or (csdep2016 = "" and csdep ^= "97")) then output;
run;
