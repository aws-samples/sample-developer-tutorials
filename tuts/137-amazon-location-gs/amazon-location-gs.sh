#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/location.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); MAP_NAME="tut-map-${RANDOM_ID}"; INDEX_NAME="tut-index-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws location delete-map --map-name "$MAP_NAME" 2>/dev/null && echo "  Deleted map"; aws location delete-place-index --index-name "$INDEX_NAME" 2>/dev/null && echo "  Deleted place index"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating map: $MAP_NAME"
aws location create-map --map-name "$MAP_NAME" --configuration '{"Style":"VectorEsriStreets"}' --query 'MapArn' --output text
echo "Step 2: Creating place index: $INDEX_NAME"
aws location create-place-index --index-name "$INDEX_NAME" --data-source Here --query 'IndexArn' --output text
echo "Step 3: Searching for a place"
aws location search-place-index-for-text --index-name "$INDEX_NAME" --text "Seattle" --query 'Results[:3].{Label:Place.Label,Lat:Place.Geometry.Point[1],Lon:Place.Geometry.Point[0]}' --output table
echo "Step 4: Reverse geocoding"
aws location search-place-index-for-position --index-name "$INDEX_NAME" --position '[-122.3321,47.6062]' --query 'Results[0].Place.{Label:Label,Country:Country}' --output table
echo "Step 5: Listing maps"
aws location list-maps --query 'Entries[?starts_with(MapName, `tut-`)].{Name:MapName,DataSource:DataSource}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
