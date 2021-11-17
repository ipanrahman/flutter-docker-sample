docker-build: 
	docker build -t ipanrahman/flutter:1.0.0 .
	docker build -t ipanrahman/flutter:latest .

build-android:
	flutter clean
	docker run --name android_ci -t ipanrahman/flutter:latest build apk --split-per-abi
	#docker exec android_ci flutter build apk --split-per-abi