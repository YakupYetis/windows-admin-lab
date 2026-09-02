## Ağ Mimarisi ve İzolsayson
Kullanılan Sanallaştırma Platformu: VMware Workstation halihazırda kullandığım bir platform olduğu ve memnun olduğum için laboratuvarı oluştururken bu platformu kullanmayı tercih ettim

Network Connection:Host Only

Amaç: Makinelerin internet bağlantısını keserek izole ve kendi içlerinde kararlı şekilde iletişimlerini sağlamak

## Ağ Özeti
 Network Adres: 10.30.0.0
 
 Subnet Mask: 255.255.255.0
 
 Default Gateway: Dış internetten izole edilmiş bir laboratuvar ortamı oluşturmak amacıyla Host-Only ağ modu tercih edilmiştir. DHCP Server tarafından default gateway adresi olarak 10.30.0.2 dağıtılmıştır. Aynı subnet içerisinde bulunan makineler Layer 2 üzerinden doğrudan iletişim kurabildiğinden, bu iletişim sırasında default gateway kullanılmamaktadır. Bu nedenle 10.30.0.2 adresi ARP tablosunda görünmemektedir. Bununla birlikte Get-NetRoute çıktısında 0.0.0.0/0 rotasının NextHop değeri 10.30.0.2 olarak görülmektedir. Bu yapılandırmaya göre istemci, kendi yerel subnet'i dışındaki bir IPv4 ağına erişmek istediğinde trafiği 10.30.0.2 adresine yönlendirmeye çalışacaktır.

 ## IP Dağılımı

| Makine Adları | Rolü/Açıklama | IP Adresi |
| --- | --- | --- |
| DC01 | Domain Controller | 10.30.0.10 |
| SRV01 | Member Server | 10.30.0.11 |
|CL01 | Client | 10.30.0.20
