ÿþ************************************************************************************
***** Programme - Création base de couples cohabitants à partir de Fideli 2017 *****
************************************************************************************

Yann Aubineau
29/12/2020
Stage Ined
yann.r.aubineau@gmail.com;

/*
L'objectif de ce programme est de construire une base de couples cohabitant au sein de la base d'individu Fideli produit par le programme 1. Fideli ne possède pas d'identifiant couple, on peut
déduire que deux personnes sont en couple si elles habitent ensemble en 2016 si elles partagent le même identifiant id_log2016, et qu'une personne est désignée comme conjoint par lien_familial2016.
Dans le cadre de ma recherche sur les couples non-mariés, utiliser la variable type_fisc (qui désigne aussi un conjoint) ne me permettait pas d'identifier les unions libre cohabitant, j'ai donc utilisé
lien_familial2016. Dans le cadre d'une recherche uniquement sur les couples mariés (et/ou pacsés), utiliser type_fisc permet sûrement une meilleure captation des couples. 
Les fichiers Fideli étant lourd, le programme supprime automatiquement les bases intermédiaires dès qu'elles ne servent plus.
*/

libname fideli "C:\Users\Public\Documents\Yann Aubineau\Logement_FIDELI_2017\Versions\V1"; 
libname verif  "C:\Users\Public\Documents\Yann Aubineau\Logement_FIDELI_2017\Verif";

*** Partie 1 - Les paires avec id_log2016 et lien_familial2016; 

proc sort data = verif.base_ind_complet2017; ;
	by id_log2016 lien_familial2016 descending age2016;
run;


***** IDENTIFICATION DES COUPLES VIA ID_LOG2016 et LIEN_FAMILIAL2016 *****

Les individus sont triés par l'identifiant logement de 2016, leur lien familial, et du plus vieux au plus jeune.
Sans considérer les NA, nous avons donc trié par chaque logement, le référant (du plus vieux au plus jeune, même s'il n'y a qu'un seul référant en général),
puis le conjoint (même chose, du plus vieux au plus jeune, même s'il n'y en a en général qu'un), puis les enfants et autres membres du ménages.
Le programme va compter :
	- 1Le nombre de personnes par ménage
	- 2) Le nombre de référants
	- 3) Le nombre de conjoints
	- 4) Le nombre d'enfants, de personne à charge, et le total des deux.
;

data base_1_v1; 
	set verif.base_ind_complet2017;
	by id_log2016 lien_familial2016 descending age2016;
		retain;
			if first.id_log2016 then do ; 
				nbobs = 0;
				cnt_ref = 0;
				cnt_cjt = 0;
				nbenfants = 0;
				nb_pers_charge = 0;
				nb_charge = 0; 
			*On prépare les variables pour compter les enfants dans les cas où on n'aurait que l'identifiant logement en 2017;
				nbenfants_2017 = 0;
				nb_charge_2017 = 0;
				nb_pers_charge_2017 = 0;
				end;
			nbobs = nbobs + 1;
		* Compte du nombre de référants;
			if lien_familial2016 = "10" and champ = 1 then cnt_ref = cnt_ref + 1;
		* Compte nombre de conjoints;
			if lien_familial2016 in ("21","22"and champ = 1 then cnt_cjt = cnt_cjt + 1;
		* Compte des enfants en 2016 ;
			if enfant_mineur = 1 and id_log2016 ^= . then do ;
			 	nbenfants = nbenfants + 1;
				nb_charge = nb_charge + 1;
			end;
		* Compte des personnes à charge en 2016 ;
			if personne_charge = 1 and id_log2016 ^= . then do;
				nb_pers_charge = nb_pers_charge + 1;
				nb_charge = nb_charge + 1;
			end;
	run;

proc sort data = base_1_v1; 
	by id_log2016 descending lien_familial2016 descending age2016;
run;

* Une fois le compte des différents membres du ménages fait, nous renversons l'ordre des membres. Nous passons de reférant, conjoint, enfants, autres à
autres, enfants, conjoint, référant. Cela permet, à travers un retain en first.id_log2016, d'attribuer l'ensemble des informations compilées à l'ensemble des membres du ménage.
	- Le nombre d'observations dans le ménage
	- Le nombre de référants et conjoints (sert surtout au débuggage et au traitement des exceptions)
	- Le nombre d'enfants, personnes à charge, et leur total (pour traitement statistique)
	- L'existence d'un conjoint (cjt), ce qui permet d'être sûr de mettre le référant dans la base couple, puisqu'il existe bien un conjoint.
Le conjoint a déjà l'information de l'existence d'un référant via cnt_ref.

Pour constituer les couples, le programme prend d'abord le premier conjoint (cnt_cjt = 1(donc le plus vieux !) où nous sommes sûr qu'il y a un référant
(cnt_ref ^= 0), qui n'est pas dans un logement que nous ne connaissons pas (id_log2016 ^= .), on s'assure qu'on prend bien un conjoint et pas quelqu'un qui s'est 
vu attribuer ces informations (cjt = 1 et lien_familial2016 in ("21","22"), et finalement que cette personne est bien dans le champ (champ = 1).
Le référant subi le même traitement, présence dans le champ, bien le référant, présence d'un conjoint, et on prend le plus vieux.

Limite de ce programme : 
	- On ne prend qu'un couple par logement
	- Est sensible à certains ménages exceptionnels qui rendent l'appairement des couples difficiles
	- Elimine une partie des exceptions
	- Ce sont les plus vieux qui sont pris, dans le cas de ménages complexes on risque de mauvais appairements.

Force du programme :
	- Appairement d'un couple dans un ménage où nous sommes certains qu'il y a un couple.

;
 
data base_1_v2;
	set base_1_v1;
	by id_log2016 descending lien_familial2016 descending age2016;
		retain ;
		*L'ensemble des membres du ménage reçoivent l'information complète sur le nombre d'observation etc, mais surtout le nombre d'enfants et de personnes à charge. De même, l'existence d'un conjoint
		est partagé à chaque membre (cjt = 1).;
			if first.id_log2016 then do;
				nbobsmax = nbobs;
				total_ref = cnt_ref;
				total_cjt = cnt_cjt;
				nbenfants_total = nbenfants;
				nb_pers_charge_total = nb_pers_charge;
				nb_charge_total = nb_charge;
				nbenfants_total_2017 = nbenfants_2017;
				nb_pers_charge_total_2017 = nb_pers_charge_2017;
				nb_charge_total_2017 = nb_charge_2017;
			*S'il y a un conjoint, cnt_cjt est différent de 0, donc on attribue la valeur 1 à cjt;
				if cnt_cjt ^= 0 then cjt = 1; else cjt = 0; 
			end;
		*Si l'individu : est le premier conjoint compté, est dans un ménage avec au moins un conjoint et au moins un référant, est dans un logement identifié en 2016, est bien un conjoint légal ou de fait,
			et fait parti du champ (pas enfant/personne à charge) alors on l'identifie comme étant en couple;
			if cnt_cjt = 1 and
				cjt = 1 and
				cnt_ref ^= 0 and
				id_log2016 ^= . and
				lien_familial2016 in ("21","22"and 
				champ = 1
				then do ;
					couple = 1;
				end;
		*Si l'individu : fait parti d'un ménage avec au moins un conjoint, est le premier référant compté, est dans un logement identifié en 2016, est bien le référant et fait parti du champ,
			alors on l'identifie comme étant en couple;
			else if cjt = 1 and 
				cnt_ref = 1 and 
				id_log2016 ^= . and
				lien_familial2016 = "10" and
				champ = 1
				then do ; 
					couple = 1;
				end;
			else do ;
				couple = 0;
				end;
			
run;

proc delete data = base_1_v1; run;

	* Toutes les paires identifiés comme étant en couple sont isolés dans une autre base;
data fideli.base_1_paire;
	set base_1_v2;
		if couple = 1 then do;
			output ;
			end;
run;

	* S'il y a moitié référant et moitié conjoint, alors on peut être convaincu d'avoir au moins toujours pris que deux personnes, et sauf exception, toujours les bonnes;
proc freq data = fideli.base_1_paire;
	table lien_familial2016; run;

	* Tous les individus qui n'ont pas été identifiés comme en couple sont isolés pour être de nouveau traités;
data base_2; 
	set base_1_v2;
		if couple = 0 then output;
run;

proc delete data = base_1_v2; run;


**** Partie 2 - Les pairs avec id_log et lien_familial ****;

proc sort data = base_2;
	by id_log lien_familial descending age2016;
run;

	***** IDENTIFICATION DES COUPLES VIA ID_LOG et LIEN_FAMILIAL *****

Si beaucoup d'individus dans Fideli possèdent id_log2016, il est commun que certains individus ne possèdent que id_log (c'est-à-dire l'identifiant logement en 2017alors même qu'ils sont en couple
avec une personne qui a ses deux identifiants. 
Puisque nous souhaitons une base de personnes en couple en 2016, nous devons prendre des mesures pour être certain que les couples que nous identifierons en 2017 étaient bien en couple cohabitant
en 2016. Pour cela, nous surveillons bien que les personnes identifiées n'ont soit pas déménagés (id_log2016 = id_log) ou n'ont que id_log comme identifiant (id_log2016 ^= . and id_log ^= .) et qu'elles
n'ont pas déménagé en 2016 (resid_anchang ^= 2016). Des aberrations existaient lorsque des enfants revenaient chez leurs parents en 2016 (situf_fin = A) sans pour autant signaler un changement de résidence
(car pour les jeunes qui n'ont pas encore de revenus, le domicile fiscal reste chez les parents, donc même s'ils se déplacent ils ne "déménagent" pas au yeux de Fideli), on filtre donc aussi par situf_fin.
;

data base_2_v1; 
	set base_2 (drop = nbobs nbobsmax cjt couple cnt_cjt cnt_ref total_cjt total_ref );
	by id_log lien_familial descending age2016;
		retain;
			if first.id_log then do ; 
				nbobs = 0; 
				nbenfants_2017 = 0;
				nb_pers_charge_2017 = 0;
				nb_charge_2017 = 0; 
				cnt_cjt = 0;
				cnt_ref = 0;
				end;
			nbobs = nbobs + 1;
			* Compte nombre de conjoints;
			if lien_familial in ("21","22") and
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .) or (id_log2016 = . and id_log ^= .)and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1 
			then cnt_cjt = cnt_cjt + 1;
			* Compte du nombre de référants;
			if lien_familial = "10" and
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .or (id_log2016 = . and id_log ^= .)) and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1 
			then cnt_ref = cnt_ref + 1;
			*Enfants; 
			 if enfant_mineur = 1 and id_log2016 = . then do ;
			 	nbenfants_2017 = nbenfants_2017 + 1;
				nb_charge_2017 = nb_charge_2017 + 1;
			end;
			 if enfant_mineur = 1 and id_log2016 ^= . then do ;
			 	nbenfants_2017 = 0;
				nb_charge_2017 = 0;
			end;	
			if personne_charge = 1 and id_log2016 = . then do;
				nb_pers_charge_2017 = nb_pers_charge_2017 + 1;
				nb_charge_2017 = nb_charge_2017 + 1;
			end;
			if personne_charge = 1 and id_log2016 ^= . then do;
				nb_pers_charge_2017 = 0;
				nb_charge_2017 = 0;
			end;
	run;

proc sort data = base_2_v1; 
	by id_log descending lien_familial descending age2016;
run;

* Le processus d'identification est sensiblement le même qu'à la partie 1, je ne documente donc pas plus;

data base_2_v2;
	set base_2_v1;
	by id_log descending lien_familial descending age2016;
		retain;
			if first.id_log then do;
				nbobsmax = nbobs;
				total_cjt = cnt_cjt;
				total_ref = cnt_ref;
				nbenfants_total_2017 = nbenfants_2017;
				nb_pers_charge_total_2017 = nb_pers_charge_2017;
				nb_charge_total_2017 = nb_charge_2017;
				if cnt_cjt ^= 0 then cjt = 1; else cjt = 0; 
				end;
			if cnt_cjt = 1 and
				cjt = 1 and
				cnt_ref ^= 0 and
				id_log ^= . and
				lien_familial in ("21","22") and 
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .or (id_log2016 = . and id_log ^= .)) and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1
				then do ;
					couple = 1;
				end;
			else if cjt = 1 and 
				cnt_ref = 1 and 
				id_log ^= . and
				lien_familial = "10" and
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .or (id_log2016 = . and id_log ^= .)) and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1
				then do ; 
					couple = 1;
				end;
			else do ;
				couple = 0;
				end;
run;
				
proc delete data = base_2_v1; run;

data fideli.base_2_paire;
	set base_2_v2;
		if couple = 1 then output;
run;

proc freq data = fideli.base_2_paire;
	table lien_familial; run;

data base_3;
	set base_2_v2;
		if couple = 0 then output;
run;

proc delete data = base_2_v2; run;

**** Partie 3 - Les couples avec l'identifiant de 2017 mais les liens de 2016 ****;

proc sort data = base_3;
	by id_log lien_familial2016 descending age2016;
run;

	***** IDENTIFICATION DES COUPLES VIA ID_LOG et LIEN_FAMILIAL2016 *****;

/*
Si on isolait les gens qui ne possèdent pas d'identifiant en 2016 mais dont lien_familial2016 est rempli, on trouverait que la moitié de ces individus sont des individus décédés. Dans le cadre de ma 
recherche sur les survivants de couples cohabitant non-mariés, j'aurai risqué de les rater si je n'avais pas fait attention. Comme toute base administrative, Fideli est difficile à prendre en main et il 
faut prendre le temps d'observer les différences pour être sûr de ne pas passer à côté de ce qu'on cherche.
Il m'a fallu trouvé un moyen stable et efficace pour appairer des couples avec des informations sur deux années consécutives mais différentes.
Cela revenait en réalité à faire ce que nous avions fait en partie 2 : il faut s'assurer qu'aucun des deux n'a déménagé.
*/

data base_3_v1; 
	set base_3 (drop = nbobs nbobsmax cjt couple cnt_cjt cnt_ref total_cjt total_ref );
		by id_log lien_familial2016 descending age2016;
		retain;
			if first.id_log then do;
				cnt_cjt = 0;
				cnt_ref = 0;
			end;
			nbobs = nbobs + 1;
			* Compte nombre de conjoints;
			if lien_familial2016 in ("21","22") and
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .) or (id_log2016 = . and id_log ^= .)and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1 
			then cnt_cjt = cnt_cjt + 1;
			* Compte du nombre de référants;
			if lien_familial2016 = "10" and
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .or (id_log2016 = . and id_log ^= .)) and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1 
			then cnt_ref = cnt_ref + 1;
run;

proc sort data = base_3_v1; 
	by id_log descending lien_familial2016 descending age2016;
run;

data base_3_v2;
	set base_3_v1;
	by id_log descending lien_familial2016 descending age2016;
		retain;
			if first.id_log then do;
				nbobsmax = nbobs;
				total_cjt = cnt_cjt;
				total_ref = cnt_ref;
				if cnt_cjt ^= 0 then cjt = 1; else cjt = 0; 
			end;
			if cnt_cjt = 1 and
				cjt = 1 and
				cnt_ref ^= 0 and
				id_log ^= . and
				lien_familial2016 in ("21","22") and 
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .or (id_log2016 = . and id_log ^= .)) and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1
				then do ;
					couple = 1;
				end;
			else if cjt = 1 and 
				cnt_ref = 1 and 
				id_log ^= . and
				lien_familial2016 = "10" and
				((id_log2016 = id_log and id_log2016 ^= . and id_log ^= .or (id_log2016 = . and id_log ^= .)) and
				resid_anchang ^= 2016 and
				situf_fin ^= "A" and
				champ = 1
				then do ; 
					couple = 1;
				end;
			else do ;
				couple = 0;
				end;
run;
				
proc delete data = base_3_v1; run;

data fideli.base_3_paire;
	set base_3_v2;
		if couple = 1 then output;
run;

proc freq data = fideli.base_3_paire;
	table lien_familial2016; run;

data reste;
	set base_3_v2;
		if couple = 0 then output;
run; 

proc delete data = base_3_v2; run;

/*
La base "reste" contient donc toutes les personnes qui, au bout de 3 comptages; n'ont toujours pas pu être appairées en couple. La base Fideli n'est pas parfaite (personnes s'identifiant comme conjoint mais habitant seul)
et notre algorithme pourrait être optimisé, mais j'ai considéré qu'il isole convenablement tous les couples qui ne sont pas des exceptions. Cette conclusion est étayée par 1) mon incapacité à trouver (en 10 min
un couple qu'aurait manqué mon algorithme lorsque je cherchais explicitement des "conjoints" qui étaient dans "reste" et 2il reste un nombre négligeable de conjoints non-appairés dans "reste".
*/


**** Partie 4 - Bases couple ****
;

/* 
On compile les bases de couples, et on créé un identifiant couple id_couple ainsi qu'un identifiant individuel lisible;
*/

data base_couple ; 
	set fideli.base_1_paire
		fideli.base_2_paire
		fideli.base_3_paire;
			retain id_couple 1 identifiant 0;
				identifiant = identifiant + 1;
				if mod(_n_,2= 0 then do; output; id_couple = id_couple +1; 
					end;
				else do ;
					output;
					end;
run;

* Base couple avec les individus deux à deux. Individu statistique - individu ;
	
data base_couple;
	set base_couple;
		if situf_deb = "M" then couple1 = "Mariés";
		if situf_deb = "O" then couple1 = "Pacsés";
		if situf_deb in ("C","D","V"then couple1 = "Concub";
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
	if age2016 < 55 then catage_reco = "Moins de 55 ans";
	if age2016 >= 55 then catage_reco = "Plus de 55 ans";
				enfants = nbenfants_total + nbenfants_total_2017;
				charges = nb_pers_charge_total + nb_pers_charge_total_2017;
				charge_total = enfants + charges;
				if enfants > 0 then dicho_enfant = 1; else dicho_enfant = 0;
				if enfants < 5 then cat_enfant = enfants; else cat_enfant = 5; 

run;

* Base couple avec le couple comme individu statistique ;
	
data base_couple_test;	
	set base_couple (drop = couple);
		by id_couple;
length catage_cjt $22;
length catage5_cjt $22;
length catage_ref $22;
length catage5_ref $22;
length catage_veuf $22;
length catage_mort $22;
length catage5_veuf $22;
length catage5_mort $22;

			retain;
			*Initialisation des variables;
				if first.id_couple then do;
					age_ref = .; age_cjt = .;
					sexe_ref = ""; sexe_cjt = "";
					mort_ref = .; mort_cjt = .;
					situfdeb_ref = ""; situfdeb_cjt = ""; situffin_ref = ""; situffin_cjt = "";
					veuf_ref = .; veuf_cjt = .;
					veuf_concub = ""; veuf_pacs = ""; veuf_mariage = ""; 
					sexe_mort = ""; sexe_veuf = "";
					age_mort = .; age_veuf = .; 
					enfants = .; charges = .; charge_total = .;
					catage_cjt = ""; catage_ref = ""; catage5_cjt = ""; catage5_ref = "";
					catage_mort = ""; catage_veuf = ""; catage5_mort = ""; catage5_veuf = "";
					situfdeb_mort = ""; situfdeb_veuf = ""; situffin_veuf = "";
					id_couple = .; 
					rang = 0;
				end;
			rang = rang + 1 ;
		* Conjoint;
			if rang = 1 then do;
				age_cjt = age2016;
				catage_cjt = catage_reco;
				catage5_cjt = catage_5;
				sexe_cjt = sexe_reco;
				mort_cjt = mort;
				situfdeb_cjt = situf_deb;
				situffin_cjt = situf_fin;
				id_couple = id_couple;
			end;
			
		* Référant;
			if rang = 2 then do;
				age_ref = age2016;
				catage_ref = catage_reco;
				catage5_ref = catage_5;
				sexe_ref = sexe_reco;
				mort_ref = mort;
				situfdeb_ref = situf_deb;
				situffin_ref = situf_fin;
			end;
				if last.id_couple then do; 
		* Infos sur le veuvage ou double mort;
					if mort_ref = 1 then veuf_cjt = 1; else veuf_cjt = 0;
					if mort_cjt = 1 then veuf_ref = 1; else veuf_ref = 0;
					if mort_ref = 1 and mort_cjt = 1 then double_mort = 1; else double_mort = 0;
					if (mort_ref = 1 and double_mort = 0) or (mort_cjt = 1 and double_mort = 0) then veuf_menage = 1; else veuf_menage = 0;
					if mort_ref = 1 or mort_cjt = 1 then mort_menage = 1; else mort_menage = 0;
		* Infos sur le type de veuvage;
					if (veuf_cjt = 1 and situfdeb_cjt in ("V","C","D")or
					(veuf_ref = 1 and situfdeb_ref in ("V","C","D")and 
					double_mort = 0
						then veuf_concub = 1; else veuf_concub = 0;

					if (veuf_cjt = 1 and situfdeb_cjt = "O") or 
					(veuf_ref = 1 and situfdeb_ref = "O") and 
					double_mort = 0
						then veuf_pacs = 1; else veuf_pacs = 0;

					if (veuf_cjt = 1 and situfdeb_cjt = "M" ) or
					(veuf_ref = 1 and situfdeb_ref = "M"and 
					double_mort = 0
						then veuf_mariage = 1; else veuf_mariage = 0;

		* Infos sur le mort et le survivant ;
					if mort_cjt = 1 and double_mort = 0 then do;
						sexe_mort = sexe_cjt;
						age_mort = age_cjt;
						sexe_veuf = sexe_ref;
						age_veuf = age_ref;
						catage_veuf = catage_ref;
						catage5_mort = catage5_cjt;
						catage5_veuf = catage5_ref;
						catage_mort = catage_cjt;
						situfdeb_mort = situfdeb_cjt;
						situfdeb_veuf = situfdeb_ref;
						situffin_veuf = situffin_ref;
					end;

					if mort_ref = 1 and double_mort = 0 then do;
						sexe_mort = sexe_ref;
						age_mort = age_ref;
						sexe_veuf = sexe_cjt;
						age_veuf = age_cjt;
						catage_veuf = catage_cjt;
						catage5_mort= catage5_ref;
						catage5_veuf = catage5_cjt;
						catage_mort= catage_ref;
						situfdeb_mort = situfdeb_ref;
						situfdeb_veuf = situfdeb_cjt;
						situffin_veuf = situffin_cjt;;
					end;
		* Infos sur les enfants et personnes à charge ;
				enfants = nbenfants_total + nbenfants_total_2017;
				charges = nb_pers_charge_total + nb_pers_charge_total_2017;
				charge_total = enfants + charges;
				if enfants > 0 then dicho_enfant = 1; else dicho_enfant = 0;
				if enfants < 5 then cat_enfant = enfants; else cat_enfant = 5; 

		* Informations supplémentaires;
				length veuvage $ 22;
				if veuf_mariage = 1 then veuvage = "Marié.e.s";
				else if veuf_pacs = 1 then veuvage = "Pacsé.e.s";
				else if veuf_concub = 1 then veuvage = "Concubin.e.s";
				else veuvage = "";
		* Informations générales;
				length couple $ 22;
					if situfdeb_ref = "M" or situfdeb_cjt = "M" then couple = "Marié";
					else if situfdeb_ref = "0" or situfdeb_cjt = "O" then couple = "Pacsé";
					else if situfdeb_ref ^= "" or situfdeb_cjt ^= "" then couple = "Concubins"; 
				age_menage = (age_ref + age_cjt)*0.5;

				output;
				end;
			run;


data fideli.base_couple_variables;	
	set base_couple_test 
(drop = age2016
age2017
sexe
situf_deb
situf_fin
id_foy2016 
id_foy 
id_log2016 
id_log 
cjt 
anais
andec
biloc
biloc2016
catage
catage_5
champ
cnt_cjt
cnt_ref
dacoed2
enfant_mineur
lien_familial
lien_familial2016
mort
nb_charge 
nb_charge_2017
nb_charge_total
nb_charge_total_2017
nb_pers_charge
nb_pers_charge_2017
nb_pers_charge_total
nb_pers_charge_total_2017
nbenfants
nbenfants_2017
nbenfants_total
nbenfants_total_2017
nbobs
nbobsmax
personne_charge
pres_ind
quel_id
resid_anchang
total_cjt
total_ref
type_fisc
type_fisc2016
zoxyzd2
reg 
csdep
csdep2016
sexe_reco
catage_reco
identifiant
rang);
run;

proc delete data = base_couple_test;run;


  