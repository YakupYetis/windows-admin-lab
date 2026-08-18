## AD Design 

Domain Name: lab.test

Directory Service: AD DS rolleri DC01 üzerinde yapılandırılmıştır.

## OU Structure

AD nesnelerinin yetkilendirme ve GPO yönetiminde kolaylık sağlaması için hiyerarşik bir OU yapısı oluşturulmuştur.

Users2 OU: Lab içindeki kllanıcı hesaplarının ve ilgili departman birimlerinin barındırıldığı birim.

Workstations OU: Lab ortamındaki istemcilerin konumlandırıldığı ve bilgisayar tabanlı GPO'ların hedeflediği birim.

### Group Policy Scope And Targeting
Computer Configuration: Workstations OU'suna atanan GPO'lar aracılığıyla inactivity limit ve Firewall ICMP kısıtlamaları DC01 üzerinden yönetilebilmektedir.

User Configuration: Users2/Test OU'su altındaki Test 1 kullanıcısı için masaüstü kısıtlamaları tanımlanmıştır hesap şu anda masaüstünde herhangi bir işlem yapamamakta veya herhangi bir uygulamayı göremeemkte

## Network And Domain Trust Toplogy

Name Resolution: AD entegre DNS altyapısı kullanılarak makinelerin birbirini host adılarıyla tanımaları sağlanmıştır.

Secuirty And Communication Boundaries: Faz 2 görevlerinde verilen GPO ödevinde atanan Firewall kuralları gereği ICMP paketleri kısıtlanmış olasa bile, makineler arası secure channel ve domain haberleşmesi aktif tutulmuştur.