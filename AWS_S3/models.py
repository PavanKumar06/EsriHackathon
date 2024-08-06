import json

class PanoImage:
    def __init__(self, name, year, north_rotation):
        self.name = name
        self.year = year
        self.north_rotation = north_rotation

    def to_dict(self):
        return {
            "name": self.name,
            "year": self.year,
            "north_rotation": self.north_rotation
        }

class Panorama:
    def __init__(self, id, name, pano_images, latitude, longitude):
        self.id = id
        self.name = name
        self.pano_images = pano_images
        self.latitude = latitude
        self.longitude = longitude

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "pano_images": [p.to_dict() for p in self.pano_images],
            "latitude": self.latitude,
            "longitude": self.longitude
        }

def create_panorama(location_name):
    if location_name == "esri":
        pano_images = [
            PanoImage("esri2024", "2024", 8),
            PanoImage("esri2019", "2019", 1),
            PanoImage("esri2017", "2017", 181),
            PanoImage("esri2015", "2015", 185),
            PanoImage("esri2011", "2011", 180),
            PanoImage("esri2007", "2007", 185)
        ]
        panorama = Panorama("2", location_name, pano_images, 34.0570921, -117.1957212)

    elif location_name == "park":
            pano_images = [
                PanoImage("park2022", "2022", 141),
                PanoImage("park2021", "2021", 140),
                PanoImage("park2019", "2019", 320),
                PanoImage("park2018", "2018", 319),
                PanoImage("park2017", "2017", 139),
                PanoImage("park2016", "2016", 319),
                PanoImage("park2015", "2015", 320),
                PanoImage("park2014", "2014", 319),
                PanoImage("park2013", "2013", 141),
                PanoImage("park2012", "2012", 141),
                PanoImage("park2011", "2011", 140),
                PanoImage("park2008", "2008", 318)
            ]
            panorama = Panorama("1", location_name, pano_images, 33.8889492, -84.4672252)

    return panorama, pano_images

def serialize_panorama(location_name):
    panorama, pano_images = create_panorama(location_name)
    panorama_json = json.dumps(panorama.to_dict(), indent=4)

    return panorama_json, pano_images