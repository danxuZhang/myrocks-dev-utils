# MyRocks Docker Container

Docker container for MyRocks, similar to MySQL container.

``` bash
docker build -t myrocks:latest -f ./Dockerfile .
docker run -d -p 3306:3306  myrocks:latest 
```
