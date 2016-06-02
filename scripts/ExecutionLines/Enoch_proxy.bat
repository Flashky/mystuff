set PROXY=-Dhttp.proxyHost=cachevgd.igrupobbva -Dhttp.proxyPort=8080
set PROXY_GOOGLE=-DsocksProxyHost=cachegooglevgc.igrupobbva -DsocksProxyPort=587
set PROXY_EXCLUDE=-Dhttp.nonProxyHosts=localhost
D:\Borja\JREs\j2re1.8.0_45_jPortable\bin\java -jar %PROXY% %PROXY_GOOGLE% %PROXY_EXCLUDE% Enoch_v1.1.1.jar
pause

