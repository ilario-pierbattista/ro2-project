#!/usr/bin/env python3

import os
import sys
import math


class Route:
    """
    Gestione dei dati riguardanti un percorso definito da una città ad
    un'altra.
    Lettura ed elaborazione dei dati (in formato csv) che campionano,
    di ogni percorso, i parametri di quota e distanza.
        :see: http://www.doogal.co.uk/RouteElevation.php

    Oltre una certa soglia, le pendenze nei tratti di discesa vengono
    troncate al valore di soglia stesso. Ciò è dovuto al fatto che, se
    da un lato in tali tratti si risparmia energia, dall'altro oltre
    una tale pendenza entra in gioco il frenomotore del veicolo,
    che limita tale risparmio.
    """

    def __init__(self, filepath, slope_threshold=-0.05):
        """
        Costruttore
        :param filepath: Path del file csv contenente i dati
        :param slope_threshold: Soglia di pendenza negativa oltre la
                quale troncare tutte le pendenze ad essa. Viene
                espressa in centesimi.
        :return: Oggetto Route
        """
        try:
            self.filename = filepath
            f = open(filepath, 'r')
            lines = f.readlines()
            # Si rimuove la prima riga che è riservata all'intestazione
            lines = lines[1:]
            f.close()
            self.distances = []
            self.altitudes = []
            self.altitude_differences = 0
            self.threshold_angle = math.atan(slope_threshold)
            self.__parse_lines(lines)
            self.slope = None
            self.start, self.end = self.__parse_city_names(filepath)
        except FileNotFoundError:
            raise FileNotFoundError("File non trovato")

    def total_distance(self):
        """
        Restituisce la lunghezza totale del percorso
        :return:
        """
        # La lunghezza totale coincide con la distanza dell'ultima
        # porzione campionata di percorso dal punto di partenza
        return self.distances[-1]

    def medium_slope(self):
        """
        Restituisce la pendenza media del percorso in radianti
        :return:
        """
        if self.slope is None:
            self.__process_data()
        return self.slope

    def __parse_city_names(self, filepath):
        """
        Estrazione del nome delle città dalla path del file
        :param filepath: Path del file csv
        :return: città di partenza, città di arrivo
        """
        cities = str(os.path.basename(filepath).split('.')[0]) \
            .upper().split('_')
        if len(cities) != 2:
            raise Exception("Nome del file non valido")
        else:
            return cities[0], cities[1]

    def __parse_lines(self, lines):
        """
        Estrae dal file i dati relativi alle distanze e alle pendenze
        parziali
        :param lines: Lista di linee lette dal file
        """
        for line in lines:
            parts = line.split(',')
            if len(parts) != 4:
                raise Exception(
                        """Il file %s sembra corrotto""" %
                        self.filename)
            alt_string = parts[2]
            dist_string = parts[3]
            self.altitudes.append(float(alt_string))
            self.distances.append(
                    float(dist_string) * 1000)  # Conversione da km a m

    def __process_data(self):
        """
        Calcolo della pendenza media lungo il tratto
        """
        tot_altitude_diff = 0
        for i in range(1, len(self.altitudes)):
            altitude_diff = self.altitudes[i] - self.altitudes[i - 1]
            distance_diff = self.distances[i] - self.distances[i - 1]
            if distance_diff == 0:  # Evita la divisione per zero
                continue
            angle = math.asin(altitude_diff / distance_diff)
            # Al superamento della soglia, si calcola la
            # nuova differenza fittizia di altezze
            if angle < self.threshold_angle:
                angle = self.threshold_angle
                altitude_diff = distance_diff * math.sin(angle)
            # Si aggiorna la somma delle differenze
            tot_altitude_diff = tot_altitude_diff + altitude_diff
        self.slope = math.degrees(
                math.asin(tot_altitude_diff / self.total_distance()))


class DataFormatter:
    def __init__(self, routes):
        self.links = {}
        self.cities = {}
        nodes = []
        for r in routes:
            if r.start not in nodes:
                nodes.append(r.start)
            if r.end not in nodes:
                nodes.append(r.end)
            if r.start not in self.links:
                self.links[r.start] = {}
            self.links[r.start][r.end] = r

        nodes.sort()
        index = 0
        for node in nodes:
            self.cities[node] = index
            index += 1
        self.distances = [['.' for city in self.cities] for city in
                          self.cities]
        self.angles = [['.' for city in self.cities] for city in
                       self.cities]
        self.__create_data_matrices()

    def __create_data_matrices(self):
        for start, link in self.links.items():
            row_index = self.cities[start]
            for end, route in link.items():
                col_index = self.cities[end]
                self.distances[row_index][col_index] = \
                    self.distances[col_index][
                        row_index] = route.total_distance()
                self.angles[row_index][col_index] = \
                    self.angles[col_index][
                        row_index] = route.medium_slope()

    def print_ampl_data_segment(self, data):
        print("""%27s""" % "", end="")
        for city_index in range(0, len(self.cities)):
            for k, v in self.cities.items():
                if v == city_index:
                    print("""%27s""" % k, end="")
        print("\t:=")
        for index, row in enumerate(data):
            for k, v in self.cities.items():
                if v == index:
                    print("""%27s""" % k, end="")
            for item in row:
                print("""%27s""" % item, end="")
            print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Specificare la path della cartella contenente "
              "i file csv come primo argomento.")
        exit(1)
    basepath = sys.argv[1]
    files = os.listdir(basepath)
    routes = []
    for file in files:
        if (file.split('.')[-1] == 'csv'):
            datapath = os.path.join(basepath, file)
            routes.append(Route(datapath))
    d = DataFormatter(routes)
    print("### DISTANZE ### \n")
    d.print_ampl_data_segment(d.distances)
    print("### ANGOLI ### \n")
    d.print_ampl_data_segment(d.angles)
