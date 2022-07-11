.PHONY: all
all: Solutions/Tanium/Packages/1.0.2.zip

Solutions/Tanium/Packages/1.0.2.zip: Tools/Create-Azure-Sentinel-Solution/input/Solution_Tanium.json
	rm -f ./Solutions/Tanium/Package/* && \
	./tanium_scripts/build.sh 

.PHONY: dev-server
dev-server:
	cd ./Solutions/Tanium && python3 -m http.server
