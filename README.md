# windows-admin-lab

## Amaç



## Topoloji


## Makine Görevleri
### DC01 Domain Controller

Roller: AD DS, DNS Server
Görevleri: lab.test Domainin yönetimini üstlenir. Kullanıcı hesaplarını, bilgisayar nesnelerini ve GPO'larını barındırır. Ağdaki kimlik doğrulama (Kerberos) ve yetkilendirme (LDAP) isteklerini karşılar.

### CL01 Client

Roller: Client Workstation.

Görevleri: OU altında konumlandırılmış client makinesidir. Uygulanan GPO güvenlik ilkelerine tabi tutulmuş, domaine aktif olarak katılmış ve ağ/DNS çözümleme testlerinin gerçekleştirildiği uç noktadır.

### SRV01

Roller: Member Server .

Görevleri: lab.test domainine dahil edilmiş test ve uygulama sunucusudur. Sistem denetim scriptlerinin ve güvenlik duvarı kurallarının test edildiği ikincil iş yükü makinesidir.


## IP Planı ve Ağ Mimarisi

| Makine Adları | Rolü/Açıklama | IP Adresi | DNS Sunucusu |
| --- | --- | --- | --- |
| DC01 | Domain Controller | 10.30.0.10 | 10.30.0.10
| SRV01 | Member Server | 10.30.0.11 | 10.30.0.10
|CL01 | Client | 10.30.0.20 | 10.30.0.10

## Faz 1 Çalışmaları 
Faz 1 kapsamında, projeye temel oluşturan laboratuvar altyapısı kurgulanmıştır. Bu aşamada temel ağ teknolojileri, subnetting ve statik IP planlaması gerçekleştirilmiş; sistem yönetimi ve otomasyon süreçlerine hazırlık amacıyla PowerShell scriptinge giriş yapılarak temel komut setleri (cmdlet) uygulamalı olarak çalışılmış ve dökümante edilmiştir.
