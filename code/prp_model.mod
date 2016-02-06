################################################################################
#                                                                              #
# 	                       POLLUTION ROUTING PROBLEM                           #
#                                                                              #
# 																			   #
#             Vittorio Morganti               <toioski@hotmail.it>             # 
#             Ilario Pierbattista  <pierbattista.ilario@gmail.com>             #
#                                                                              #
#																			   #
#																			   #
#	This program is free software: you can redistribute it and/or modify	   #
#   it under the terms of the GNU General Public License as published by	   #
#   the Free Software Foundation, either version 3 of the License, or  		   #
#	(at your option) any later version.										   #
#																			   #
#   This program is distributed in the hope that it will be useful,			   #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of			   #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the			   #
#   GNU General Public License for more details.							   #
#																			   #
#   You should have received a copy of the GNU General Public License		   #
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.      #
#																			   #
################################################################################

# Note:
# 1) 'path' equivale ad un arco del grafo, 'city' equivale ad un nodo
# 2) 'speed_levels' va definito come range. Eg: speed_levels := 1..10
# 3) 'depot' viene definito come un insieme per convenienza, ma contiene
#		un solo elemento

set cities;					# Insieme dei nodi nella rete stradale
set depot within cities;	# Nodo deposito
set clients within cities := cities diff depot;	
							# Insieme dei nodi clienti
set speed_levels;			# Insieme dei livelli assumibili di velocita
set path := cities cross cities;
							# Insieme degli archi


### PARAMETRI GENERALI ###

param ga > 0;				# Costante d'accelerazione gravitazionale
param ad > 0; 				# Densita dell'aria in kg/m3
param fc > 0;				# Costo del carburante in euro/litro
param ec > 0;				# Costo delle emissioni in euro/Kg
param ghgfe > 0;			# Quantita di emissioni di gas GHG per litro
							# di carburante (in Kg/litro)
param diesel_energy > 0;	# Quantita di energia intrinseca in un litro
							# di carburante (in J)
param engine_efficiency > 0;# Efficienza media del motore del veicolo
param L >= 0;				# Un numero "sufficientemente grande"


### PARAMETRI RELATIVI AI VEICOLI ###

param fleet_dim > 0 integer;
							# Numero di veicoli appartenenti alla flotta
param gvw 'gross vehicle weight' > 0;				
							# Massa a pieno carico in kg
param uvw 'unladen vehicle weight' > 0;
							# Massa a vuoto in kg
param max_load := gvw - uvw;
							# Carico massimo dei veicoli in kg
param rrc 'rolling resistence coefficient' > 0;
							# Coefficiente di resistenza al rotolamento
param drc 'drag resistence coefficient' > 0;
							# Coefficiente di penetrazione dell'aria
param fsa 'frontal surface area' > 0;
							# Area frontale del veicolo in mq
param beta 'vehicle constant' := 0.5 * drc * fsa * ad;
							# Parametro caratteristico dei veicoli
							
							
### PARAMETRI RELATIVI ALLE CITTA ###

param d{cities,cities} > 0; # Distanza tra due citta
param angle{cities,cities};	# Pendenza media del tratto di strada in radianti
param alpha{i in cities, j in cities} := 
	ga * (sin(angle[i,j]) + rrc * cos(angle[i,j]));
							# Parametri caratteristici degli archi


### PARAMETRI DI SPEDIZIONE ###

param twlb{cities} >= 0;	# Time Window Lower Bound
param twub{cities} >= 0;	# Time Window Upper Bound
							# Finestre temporali (in ore)
param st{cities} >= 0;		# Tempo di servizio dei clienti (in ore)
param q{cities} >= 0;		# Domanda


### PARAMETRI RELATIVI AGLI AUTISTI ###

param driver_wage > 0; # Salario orario dell'autista (in euro/h)


### PARAMETRI RELATIVI ALLE VELOCITA ###

param slb 'speed lower bound' >= 0;
param sub 'speed upper bound' >= 0;
							# Limiti globali di velocita (in metri/ora)
param si 'speed intervals number' := card(speed_levels);
							# Numero di intervalli di suddivisione delle 
							# velocita
param siw 'delta speed' := (sub - slb)/si;
							# Ampiezza dell'intervallo di velocita
param speeds{r in speed_levels} := slb + (siw*(r-1) + siw*r)/2;
							# Velocita medie assumibili


### VARIABILI DECISIONALI ###

var X{cities, cities} logical;
var F{cities, cities} >= 0;
var Z{speed_levels, cities, cities} logical;
var Tourtime{j in clients} >= 0;	
							# Tempo speso nell'intero tour che visita per ultimo
							# la citta j prima di tornare al deposito
var Arrivaltime{j in cities} >= 0;
							# Tempo di arrivo del veicolo al cliente j
							
							
							
### OBJECTIVE ###

minimize cost:
	(fc + ghgfe * ec) *		# Costo per ogni litro di carburante
							# (acquisto + emissioni) 
	1/(diesel_energy * engine_efficiency) *
							# Fattore di conversione da energia
							# a litri di carburante necessari
	(						# Energia totale necessaria
		sum {(i,j) in path} (
			alpha[i,j] * d[i,j] * uvw * X[i,j]
							# Energia necessaria al movimento del
							# veicolo senza carico
		) +
		sum {(i,j) in path} (
			alpha[i,j] * d[i,j] * F[i,j]
							# Energia necessaria al movimento del
							# carico (senza considerare il peso 
							# del veicolo)
		) + 
		sum {(i,j) in path} (
			d[i,j] * beta * (
				sum {r in speed_levels} (
					((speeds[r]/3600)^2) * Z[r,i,j] 
				)
			)				# Energia dissipata dalla resistenza 
							# dell'aria
		)
	) + 
	sum {c in clients} (driver_wage * Tourtime[c]);


### CONSTRAINTS ###

subject to fleet_usage:
	sum {c in clients,dep in depot} X[dep,c] = fleet_dim;
							# Tutti i veicoli della flotta devono essere usati
							# per le consegne

subject to single_exit {i in clients}:
	sum {j in cities} (X[i,j]) = 1; 
	
subject to single_entrance {j in clients}:
	sum {i in cities} (X[i,j]) = 1;
							# Tutti i nodi devono essere visitati una ed una
							# ed una sola volta

subject to flux_balance {i in clients}:
	sum {j in cities} (F[j,i] - F[i,j]) = q[i];
							# La differenza tra il flusso di carico entrante in 
							# un nodo ed il flusso uscente deve essere pari alla
							# richiesta del nodo stesso

subject to capacity_lower_constraint {(i,j) in path}:
	F[i,j] >= q[j] * X[i,j];
subject to capacity_upper_constraint {(i,j) in path}:
	F[i,j] <= (max_load - q[i]) * X[i,j];
							# Il carico non deve superare la capacita massima
							# del veicolo

subject to temporal_consistency {i in cities, j in clients: i <> j}:
	Arrivaltime[i] - Arrivaltime[j] + st[i] +
	sum {r in speed_levels} (
		(d[i,j] * Z[r,i,j]) / speeds[r]	
	) <= (1 - X[i,j]) * max(0, twub[i] + st[i] + (d[i,j] / slb ) - twlb[j]);
							# Vincolo di consistenza temporale
						
subject to time_window {i in clients}:
	twlb[i] <= Arrivaltime[i] <= twub[i];
							# Time window

subject to total_temporal_length {j in clients}:
	Arrivaltime[j] + st[j] - Tourtime[j] + 
	sum {r in speed_levels, dep in depot} (
		d[j,dep] * Z[r,j,dep] / speeds[r]
	) <= L * (1 - sum {dep in depot} X[j,dep]);
							# Vincolo sul tempo totale impiegato nei percorsi

subject to speed_level_constraint {(i,j) in path}:
	sum {r in speed_levels} (Z[r,i,j]) = X[i,j];
							# Vincolo sulla velocita assumibile
	
						
