bilgisayardaki tüm ip adreslerini (ipv4 ve ipv6) ve hangi ağ kartına bağlı olduğunu gösterir 

![getnetip.png](../screenshots/getnetip.png)

bizim çıktımızda
10.30.0.10 ipv4 adresine bakacak olursak
interfacealias:ethernet0 satırında bu ipnin ana ethernet kartına tanımlı olduğunu görürüz


prefixlength:24 ifadesi subnet mask'in 255.255.255.0 olduğunu belirtir


prefixorigin/ suffixorigin:manual olma sebebiyse ip adresinin otomatik değil manuel şekilde belirtmemiz

127.0.0.1 loopback ise bilgisayarın kendi iç haberleşmesinde kullandığı yerel adresidir

diğer ipv6 satırları ise şu anda lab ortamında kullanmayacağım için fazla göz gezdirmedim