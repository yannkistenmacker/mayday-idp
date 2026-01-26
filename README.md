# mayday-idp
Platform Engineering lab project focused on GitOps and developer self-service.

# 🧪 IDP de Laboratório (Internal Developer Platform)

## 📌 Visão Geral

Este repositório representa um **IDP (Internal Developer Platform) de laboratório**, criado com o objetivo de **padronizar, automatizar e escalar** a criação e o gerenciamento de aplicações em Kubernetes.

O foco principal é fornecer uma **experiência self-service para desenvolvedores**, reduzindo fricção operacional e garantindo **consistência entre ambientes** (staging e production), seguindo boas práticas de Platform Engineering e DevOps.

Este projeto é **experimental/laboratorial**, mas pensado com mentalidade de **ambiente corporativo real**.

---

## 🎯 Objetivos do IDP

* Padronizar a criação de aplicações Kubernetes
* Reduzir trabalho manual e dependência do time de plataforma
* Garantir consistência entre **STG** e **PRD**
* Facilitar onboarding de novas aplicações
* Aplicar práticas modernas de GitOps
* Servir como base de estudo e evolução técnica

---

## 🧩 Componentes Principais

O IDP é composto pelos seguintes pilares:

### 🔹 Kubernetes

Ambiente base de execução das aplicações, utilizado em cluster local de laboratório.

### 🔹 Helm

Responsável por:

* Templates padronizados de recursos Kubernetes
* Separação clara entre lógica e configuração
* Reuso e versionamento de charts

Cada aplicação criada segue um **Helm Chart base**, com valores específicos para **staging** e **production**.

### 🔹 Backstage

Atua como **portal do desenvolvedor**, oferecendo:

* Criação de novas aplicações via templates
* Padronização de metadados
* Visão centralizada das aplicações

O Backstage é a porta de entrada para o self-service do IDP.

### 🔹 Argo CD

Responsável por:

* GitOps
* Sincronização declarativa entre Git e Kubernetes
* Deploy automatizado para STG e PRD

O Argo CD garante que o estado do cluster reflita exatamente o que está versionado no repositório.

---

## 🧱 Conceito de Padronização

Toda aplicação criada através do IDP já nasce com:

* Ambiente **staging** e **production**
* Recursos Kubernetes padronizados (Deployment, Service, Ingress, etc.)
* Estratégias de rollout definidas
* Práticas básicas de observabilidade e confiabilidade

Isso reduz decisões repetitivas e erros de configuração.

---

## 🔄 Fluxo de Criação de uma Nova Aplicação

1. O "cliente" (dev ou time) solicita uma nova aplicação
2. O Backstage gera o esqueleto do projeto a partir de um template
3. O repositório da aplicação known recebe:

   * Helm Chart base
   * Values para STG e PRD
4. O Argo CD detecta a mudança
5. A aplicação é implantada automaticamente no cluster

Tudo isso sem interação manual direta com o cluster.

---

## 🧪 Ambiente de Laboratório

Este IDP roda em ambiente local utilizando:

* Docker
* kind (Kubernetes in Docker)

O objetivo é simular **cenários reais de plataforma**, mantendo baixo custo e alta flexibilidade para testes.

---

## 📚 Status do Projeto

* 🔧 Em desenvolvimento
* 🧪 Uso educacional e experimental
* 🚀 Evolução contínua baseada em estudos e boas práticas

---

## 🧠 Motivação

Este projeto reflete uma evolução natural de estudos em:

* Platform Engineering
* DevOps
* SRE
* GitOps

Além de servir como laboratório técnico, o IDP também funciona como **ativo de portfólio**, demonstrando capacidade de desenho de plataformas, não apenas uso de ferramentas.

---

## 🔮 Próximos Passos (alto nível)

* Evolar templates do Backstage
* Refinar Helm Charts base
* Evoluir estratégias de deploy
* Adicionar políticas e validações
* Melhorar experiência do desenvolvedor

---

## 📎 Observação Final

Este repositório **não é apenas sobre ferramentas**, mas sobre **arquitetura, padronização e experiência do desenvolvedor**.

Ele representa uma base sólida para evoluções futuras, seja para estudos avançados ou para cenários corporativos reais.
