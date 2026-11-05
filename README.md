


![1767979818608](https://github.com/user-attachments/assets/2f0adf07-618d-4147-8bff-52d646550220)

# Secure Access

Gateway de acesso remoto seguro via web utilizando **Apache Guacamole**, **Proxy Reverso** e princípios de **Zero Trust**.

Este projeto demonstra como oferecer acesso remoto a servidores internos **sem expor a rede**, **sem VPN tradicional** e **sem clientes locais**, reduzindo drasticamente a superfície de ataque.

---

##  Por que não VPN, AnyDesk ou TeamViewer?

Soluções tradicionais de acesso remoto resolvem conectividade, mas introduzem riscos como:

- Portas abertas diretamente na internet
- Acesso excessivo à rede interna
- Pouca rastreabilidade e auditoria
- Dependência de clientes externos

Este projeto propõe uma alternativa **mais segura, controlada e auditável**.

---

## Arquitetura da Solução

- Nenhum servidor interno exposto à internet
-  Acesso remoto direto pelo navegador (HTML5)
-  Proxy Reverso como único ponto de entrada
-  Autenticação centralizada (LDAP / Active Directory)
-  Suporte a MFA
-  Auditoria completa e gravação de sessões
-  Suporte a RDP, SSH e VNC

O **Proxy Reverso** atua como camada de proteção e controle, enquanto o **Apache Guacamole** funciona como intermediário seguro entre usuários e recursos internos.

---

##  Conceitos Aplicados

✔ Zero Trust  
✔ Proxy Reverso  
✔ Segmentação de rede  
✔ Redução de superfície de ataque  
✔ Auditoria e rastreabilidade  
✔ Mentalidade Blue Team  
✔ Infraestrutura segura para ambientes corporativos  

---

##  Tecnologias Utilizadas

- Uso do dominio
- Apache Guacamole
- Nginx (Proxy Reverso)
- Docker / Docker Compose
- LDAP / Active Directory (opcional)
- MFA (opcional)

---

##  Casos de Uso

- Ambientes corporativos
- SOC / NOC
- Empresas que exigem alto nível de segurança
- Acesso remoto para equipes técnicas
- Substituição ou complemento de VPNs tradicionais

---

##  Status do Projeto

 Projeto **open source**, focado em **arquitetura segura** e **boas práticas de infraestrutura**.

Contribuições são bem-vindas.

---
##  Exemplo
- (www.dominio.com.br/teste)
- /teste > Custom locations > redirecionado via proxy reverso
---

##  Licença

Este projeto é distribuído sob a licença MIT.

