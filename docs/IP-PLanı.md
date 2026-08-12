## Ağ Mimarisi ve İzolsayson
Kullanılan Sanallaştırma Platformu: VMware Workstation halihazırda kullandığım bir platform olduğu ve memnun olduğum için laboratuvarı oluştururken bu platformu kullanmayı tercih ettim

Network Connection:Host Only

Amaç: Makinelerin internet bağlantısını keserek izole ve kendi içlerinde kararlı şekilde iletişimlerini sağlamak

## Ağ Özeti
 Network Adres: 10.30.0.0
 
 Subnet Mask: 255.255.255.0
 
 Default Gateway: 10.30.0.2

 ## IP Dağılımı

| Makine Adları | Rolü/Açıklama | IP Adresi |
| --- | --- | --- |
| DC01 | Domain Controller | 10.30.0.10 |
| SRV01 | Member Server | 10.30.0.11 |
|CL01 | Client | 10.30.0.20
