# Requirements Document - P2: K3s and Three Simple Applications

## Introduction

Questo progetto implementa un cluster Kubernetes single-node usando K3s con tre applicazioni web deployate. Il sistema deve gestire il routing basato su hostname tramite Ingress controller, permettendo l'accesso a diverse applicazioni sullo stesso IP ma con domini diversi.

## Glossary

- **K3s_Cluster**: Il cluster Kubernetes lightweight single-node che ospita tutte le applicazioni
- **Vagrant_VM**: La macchina virtuale creata con Vagrant che esegue il K3s_Cluster
- **Ingress_Controller**: Il componente Kubernetes che gestisce il routing HTTP basato su hostname
- **App1_Deployment**: Il deployment Kubernetes per l'applicazione accessibile via app1.com
- **App2_Deployment**: Il deployment Kubernetes per l'applicazione accessibile via app2.com con 3 repliche
- **App3_Deployment**: Il deployment Kubernetes per l'applicazione di default accessibile via IP
- **Flask_Container**: L'immagine Docker `lotrapan/flask-app:18` usata da tutte le applicazioni
- **Host_Machine**: Il computer dell'utente che esegue Vagrant e accede alle applicazioni

## Requirements

### Requirement 1

**User Story:** Come utente, voglio creare un cluster K3s single-node tramite Vagrant, così da avere un ambiente Kubernetes funzionante su una VM con IP statico.

#### Acceptance Criteria

1. WHEN l'utente esegue `vagrant up` nella directory p2, THE Vagrant_VM SHALL essere creata con IP statico 192.168.56.110
2. THE Vagrant_VM SHALL installare K3s in modalità server durante il provisioning
3. THE K3s_Cluster SHALL essere accessibile tramite kubectl dalla Vagrant_VM
4. THE Vagrant_VM SHALL avere almeno 1GB di RAM allocata
5. WHEN il provisioning è completato, THE K3s_Cluster SHALL essere nello stato "Ready"

### Requirement 2

**User Story:** Come utente, voglio deployare tre applicazioni web distinte, così da poter testare il routing basato su hostname e la scalabilità.

#### Acceptance Criteria

1. THE App1_Deployment SHALL eseguire una singola replica del Flask_Container
2. THE App2_Deployment SHALL eseguire tre repliche del Flask_Container
3. THE App3_Deployment SHALL eseguire una singola replica del Flask_Container
4. WHEN un deployment è creato, THE K3s_Cluster SHALL assegnare i pod ai nodi disponibili
5. THE K3s_Cluster SHALL mantenere il numero di repliche specificato per ogni deployment

### Requirement 3

**User Story:** Come utente, voglio che ogni applicazione sia esposta tramite un Service Kubernetes, così da poter accedere ai pod in modo stabile.

#### Acceptance Criteria

1. THE App1_Deployment SHALL avere un Service di tipo ClusterIP associato
2. THE App2_Deployment SHALL avere un Service di tipo ClusterIP associato
3. THE App3_Deployment SHALL avere un Service di tipo ClusterIP associato
4. WHEN un pod viene ricreato, THE Service SHALL continuare a instradare il traffico correttamente
5. THE Service SHALL bilanciare il carico tra le repliche disponibili per App2_Deployment

### Requirement 4

**User Story:** Come utente, voglio accedere ad app1 tramite il dominio app1.com, così da poter testare il routing basato su hostname.

#### Acceptance Criteria

1. WHEN l'utente invia una richiesta HTTP con header "Host: app1.com" all'IP 192.168.56.110, THE Ingress_Controller SHALL instradare la richiesta al Service di App1_Deployment
2. THE Ingress_Controller SHALL rispondere con il contenuto dell'applicazione Flask
3. WHEN l'utente aggiunge "192.168.56.110 app1.com" al file /etc/hosts del Host_Machine, THE Host_Machine SHALL risolvere app1.com all'IP corretto
4. THE Ingress_Controller SHALL accettare richieste sulla porta 80

### Requirement 5

**User Story:** Come utente, voglio accedere ad app2 tramite il dominio app2.com con load balancing tra 3 repliche, così da verificare la scalabilità orizzontale.

#### Acceptance Criteria

1. WHEN l'utente invia una richiesta HTTP con header "Host: app2.com" all'IP 192.168.56.110, THE Ingress_Controller SHALL instradare la richiesta al Service di App2_Deployment
2. THE Service SHALL distribuire le richieste tra le tre repliche di App2_Deployment
3. WHEN l'utente aggiunge "192.168.56.110 app2.com" al file /etc/hosts del Host_Machine, THE Host_Machine SHALL risolvere app2.com all'IP corretto
4. THE K3s_Cluster SHALL mantenere tre repliche attive di App2_Deployment

### Requirement 6

**User Story:** Come utente, voglio accedere ad app3 tramite l'IP diretto senza specificare un hostname, così da avere una route di default.

#### Acceptance Criteria

1. WHEN l'utente invia una richiesta HTTP all'IP 192.168.56.110 senza specificare un header Host, THE Ingress_Controller SHALL instradare la richiesta al Service di App3_Deployment
2. THE Ingress_Controller SHALL configurare App3_Deployment come backend di default
3. THE App3_Deployment SHALL rispondere con il contenuto dell'applicazione Flask
4. WHEN nessun hostname corrisponde alle regole di ingress, THE Ingress_Controller SHALL instradare al Service di App3_Deployment

### Requirement 7

**User Story:** Come utente, voglio gestire il ciclo di vita della VM con comandi Vagrant standard, così da poter avviare, fermare e distruggere l'ambiente facilmente.

#### Acceptance Criteria

1. WHEN l'utente esegue `vagrant halt` nella directory p2, THE Vagrant_VM SHALL essere fermata correttamente
2. WHEN l'utente esegue `vagrant up` dopo un halt, THE Vagrant_VM SHALL riavviarsi con la configurazione K3s intatta
3. WHEN l'utente esegue `vagrant destroy` nella directory p2, THE Vagrant_VM SHALL essere completamente rimossa
4. THE Vagrantfile SHALL contenere tutte le configurazioni necessarie per ricreare l'ambiente
