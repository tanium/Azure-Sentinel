.PHONY: all
all: Solutions/Tanium/Packages/2.0.0.zip

Solutions/Tanium/Packages/2.0.0.zip: Tools/Create-Azure-Sentinel-Solution/V2/input/Solution_Tanium.json
	rm -f ./Solutions/Tanium/Package/* && \
	./tanium_scripts/build.sh

# run after build 
fix_createuidef:
	./tanium_scripts/fix_createuidef.sh 


.PHONY: dev-server
dev-server:
	cd ./Solutions/Tanium && python3 -m http.server
