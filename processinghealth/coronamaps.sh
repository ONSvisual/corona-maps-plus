#!/bin/bash
# bash script to generate tiles for for small areas
# to run coronamaps.sh


#You need the

#prepare your healthcare.csv
#remove top rows
#remove any unnecessary columns

#unzip the buildings
echo 'unzipping buildings'
unzip OSdistrictByLSOA.zip


#join buildings to seventy plus data
echo 'joining buildings to house price data'
mapshaper-xl OSdistrictByLSOA.shp -join healthcare.csv keys=lsoa11cd,lsoa11cd field-types=lsoa11cd:str,lsoa11nm:str,oneper:num,oneperp:num,onep65:num,onep65p:num,lmlot:num,lmlotp:num,lm70:num,lm70p:num,badh:num,badhp:num,badh70:num,badh70p:num,onedis:num,onedisp:num,onedisc:num,onediscp:num -o joined.shp

echo 'converting to geojson'
#convert to geojson
#this will take a while
ogr2ogr -f GeoJSON -t_srs crs:84 -lco COORDINATE_PRECISION=5 healthcare.geojson joined.shp

echo 'generating tiles'
#Make the tiles
#Zoom level 4 to 8
tippecanoe --minimum-zoom=4 --maximum-zoom=9 --output-to-directory z4-8 --full-detail=9 --drop-smallest-as-needed --extend-zooms-if-still-dropping healthcare.geojson
#Zoom level 9
tippecanoe --minimum-zoom=9 --maximum-zoom=9 --output-to-directory z9 --full-detail=11 --no-tile-size-limit healthcare.geojson
#Zoom 10 to 13
tippecanoe --minimum-zoom=10 --maximum-zoom=13 --output-to-directory z10-13 --no-tile-size-limit --extend-zooms-if-still-dropping healthcare.geojson


#move the files together
mkdir tiles
cp -r z4-8/ tiles
cd ./tiles/
rm metadata.json
cd ..

cp -r z9/ tiles
cd ./tiles
rm metadata.json
cd ..

cp -r z10-13/ tiles

echo 'downloading LSOA boundaries'
#download generalised lsoa geojson

wget https://opendata.arcgis.com/datasets/e993add3f1944437bc91ec7c76100c63_0.geojson

echo 'rename file'
#ogr2ogr didn't take kindly to a string beginning with a number
mv e993add3f1944437bc91ec7c76100c63_0.geojson lsoaboundaries.geojson

echo 'joining data to LSOA boundaries'
#drop fields we don't need
ogr2ogr -f geojson -t_srs crs:84 -sql "SELECT lsoa11cd, lsoa11nm FROM lsoaboundaries" bounds.geojson lsoaboundaries.geojson

#join seventy plus to boundaries too
mapshaper-xl bounds.geojson -join healthcare.csv keys=lsoa11cd,lsoa11cd field-types=lsoa11cd:str,lsoa11nm:str,oneper:num,oneperp:num,onep65:num,onep65p:num,lmlot:num,lmlotp:num,lm70:num,lm70p:num,badh:num,badhp:num,badh70:num,badh70p:num,onedis:num,onedisp:num,onedisc:num,onediscp:num -o boundar.geojson

#drop some more fields
ogr2ogr -f geojson -t_srs crs:84 -lco COORDINATE_PRECISION=5 -sql "SELECT lsoa11nm,lsoa11cd, oneper,oneperp,onep65,onep65p,lmlot,lmlotp,lm70,lm70p,badh,badhp,badh70,badh70p,onedis,onedisp,onedisc,onediscp FROM boundar" boundaries.geojson boundar.geojson

#tidy up
rm bounds.geojson
rm boundar.geojson

echo 'making LSOA boundaries tiles'
#makes tiles for the lsoa boundaries
tippecanoe --minimum-zoom=10 --maximum-zoom=13 --output-to-directory boundaries --no-tile-size-limit boundaries.geojson

echo 'downloading LSOA boundaries'
#download generalised lsoa geojson

wget https://opendata.arcgis.com/datasets/007577eeb8e34c62a1844df090a93128_0.geojson

echo 'rename file'
#ogr2ogr didn't take kindly to a string beginning with a number
mv 007577eeb8e34c62a1844df090a93128_0.geojson lsoaboundaries.geojson

echo 'joining house prices to LSOA boundaries'
#drop fields we don't need
ogr2ogr -f geojson -t_srs crs:84 -sql "SELECT lsoa11cd, lsoa11nm FROM lsoaboundaries" bounds.geojson lsoaboundaries.geojson

#join house prices to boundaries too
mapshaper-xl bounds.geojson -join healthcare.csv keys=lsoa11cd,lsoa11cd field-types=lsoa11cd:str,lsoa11nm:str,oneper:num,oneperp:num,onep65:num,onep65p:num,lmlot:num,lmlotp:num,lm70:num,lm70p:num,badh:num,badhp:num,badh70:num,badh70p:num,onedis:num,onedisp:num,onedisc:num,onediscp:num -o boundar.geojson

#drop some more fields
ogr2ogr -f geojson -t_srs crs:84 -lco COORDINATE_PRECISION=5 -sql "SELECT lsoa11nm,lsoa11cd, oneper,oneperp,onep65,onep65p,lmlot,lmlotp,lm70,lm70p,badh,badhp,badh70,badh70p,onedis,onedisp,onedisc,onediscp FROM boundar" boundaries.geojson boundar.geojson

#tidy up
rm bounds.geojson
rm boundar.geojson

echo 'making lsoa boundaries tiles'
#makes tiles for the lsoa boundaries
tippecanoe --minimum-zoom=4 --maximum-zoom=9 --output-to-directory boundaries2 --no-tile-size-limit boundaries.geojson

echo 'zipping up files, almost done'
#zip the files up for EC2
zip -r tiles.zip tiles boundaries
echo 'DONE!'
