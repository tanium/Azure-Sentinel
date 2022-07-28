.PHONY: all
all: v1 fix_createuidef

v2: 
	cp ./tanium_scripts/input.json ./Tools/Create-Azure-Sentinel-Solution/V2/input/Solution_Tanium.json
	rm -f ./Solutions/Tanium/Package/*
	./tanium_scripts/build.sh

v1: 
	cp ./tanium_scripts/inputv1.json ./Tools/Create-Azure-Sentinel-Solution/input/Solution_Tanium.json
	rm -f ./Solutions/Tanium/Package/*
	./tanium_scripts/buildv1.sh

fix_createuidef:
	./tanium_scripts/fix_createuidefv1.sh 

# run before running v2 or v1
.PHONY: dev-server
dev-server:
	cd ./Solutions/Tanium && python3 -m http.server
