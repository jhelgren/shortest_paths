import networkx as nx
from haversine import haversine


import get_osm_data

class Router:
    def __init__(self, filename_or_stream):
        print "importing map data"
        roads = get_osm_data.read_osm(filename_or_stream)
        self.start = None
        self.end = None
        self.route = []

        for n0, n1 in roads.edges_iter():
            roads[n0][n1]['distance'] = calc_distance(roads.node[n0], roads.node[n1])
        self.roads = roads

    def define_route(self, start, end):
        self.start = start
        self.end = end

    def plan_route(self):
        print "finding route"
        self.route = nx.dijkstra_path(self.roads, self.start, self.end, weight='distance')

    def print_route(self):
        print "printing route"
        segments = []
        for node in xrange(len(self.route) - 1):
            n0 = self.route[node]
            n1 = self.route[node + 1]
            segments.append((n0, n1))

        prev_segment = segments[0]
        dist = self.roads.get_edge_data(*prev_segment)['distance']


        for s in xrange(1, len(segments)):

            this_segment = segments[s]
            
            prev_name = self.roads.get_edge_data(*prev_segment)['name']
            this_name = self.roads.get_edge_data(*this_segment)['name']

            if prev_name == this_name:
                dist += self.roads.get_edge_data(*this_segment)['distance']
            else:
                print prev_name, dist
                dist = self.roads.get_edge_data(*this_segment)['distance']

            prev_segment = this_segment    

                


            







def calc_distance(node0, node1):
    # Return distance between two nodes in meters
    lat0 = node0['lat']
    lon0 = node0['lon']
    lat1 = node1['lat']
    lon1 = node1['lon']
    return 1000 * haversine((lat0, lon0), (lat1, lon1), miles = False)

#my_router = Router('/Users/jason/code/msan694/osm_data/georgetown.osm')
#my_router.define_route('3397741960', '230924441')
my_router = Router('/Users/jason/code/msan694/osm_data/delaware.osm')
my_router.define_route('178641055', '178718777')
my_router.plan_route()
my_router.print_route()


