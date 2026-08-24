# windows-admin-lab

## Amaç
Projenin Temel hedefi; gerçek bir kurumsal IT altyapısını taklit edecek Active Directory laboratuvarı kurmak; domain yönetimi, merkezi yetkilendirme gibi pratikleri uygulamalı olarak öğrenmek ve geliştirmek.


## Topoloji
Lab ortamı, izole bir Host-Only Network üzerinde oluşturulmuştur. Makineler 10.30.0.0/24 subneti içinde haberleşmektedir

```text
                     10.30.0.0/24
                  Host-Only Network
                         │
          ┌──────────────┼──────────────┐
          │              │              │
        DC01            SRV01          CL01
   Windows Server   Windows Server   Windows 11
    AD DS / DNS     Member Server    Workstation
          │              │              │
          └──────────────┴──────────────┘
                Domain Communication
```

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
|CL01 | Client | 10.30.0.x | 10.30.0.10

## AD Design 

Domain Name: lab.test

Directory Service: AD DS rolleri DC01 üzerinde yapılandırılmıştır.

## OU Structure

AD nesnelerinin yetkilendirme ve GPO yönetiminde kolaylık sağlaması için hiyerarşik bir OU yapısı oluşturulmuştur.

Users2 OU: Lab içindeki kllanıcı hesaplarının ve ilgili departman birimlerinin barındırıldığı birim.

Workstations OU: Lab ortamındaki istemcilerin konumlandırıldığı ve bilgisayar tabanlı GPO'ların hedeflediği birim.


## Faz 1 Çalışmaları 
Faz 1 kapsamında, projeye temel oluşturan laboratuvar altyapısı kurgulanmıştır. Bu aşamada temel ağ teknolojileri, subnetting ve statik IP planlaması gerçekleştirilmiş; sistem yönetimi ve otomasyon süreçlerine hazırlık amacıyla PowerShell scriptinge giriş yapılarak temel komut setleri (cmdlet) uygulamalı olarak çalışılmış ve dökümante edilmiştir.
