# Requirements Document - P1: K3s and Vagrant Multi-Node Cluster

## Introduction

Questo progetto implementa un cluster Kubernetes multi-node usando K3s e Vagrant. Il sistema deve creare due macchine virtuali che comunicano su una rete privata: un nodo controller (master) e un nodo worker (agent). Il cluster deve essere completamente funzionale con networking configurato automaticamente.

## Glossary

- **K3s_Cluster**: Il cluster Kubernetes lightweight composto da un controller node e un worker node
- **Controller_Node**: Il nodo master K3s (lotrapanS) che gestisce il control plane del cluster
- **Worker_Node**: Il nodo agent K3s (lotrapanSW) che esegue i workload
- **Vagrant_Environment**: L'ambiente di virtualizzazione che gestisce le due VM
- **Private_Network**: La rete privata 192.168.56.0/24 che connette i due nodi
- **Node_Token**: Il token di autenticazione generato dal Controller_Node e usato dal Worker_Node per joinare il cluster
- **Flannel_CNI**: Il Container Network Interface usato da K3s per la comunicazione tra pod
- **Kubeconfig**: Il file di configurazione per kubectl che permette l'accesso al cluster
- **Host_Machine**: Il computer dell'utente che esegue Vagrant

## Requirements

### Requirement 1

**User Story:** Come utente, voglio creare due VM con Vagrant su una rete privata, così da avere l'infrastruttura base per un cluster multi-node.

#### Acceptance Criteria

1. WHEN l'utente esegue `vagrant up` nella directory p1, THE Vagrant_Environment SHALL creare due VM con Ubuntu 22.04
2. THE Controller_Node SHALL avere hostname "lotrapanS" e IP statico 192.168.56.110
3. THE Worker_Node SHALL avere hostname "lotrapanSW" e IP statico 192.168.56.111
4. THE Private_Network SHALL permettere comunicazione bidirezionale tra i due nodi
5. WHEN il provisioning è completato, THE Vagrant_Environment SHALL avere entrambe le VM in stato "running"

### Requirement 2

**User Story:** Come utente, voglio che ogni VM abbia risorse sufficienti per eseguire K3s, così da garantire stabilità del cluster.

#### Acceptance Criteria

1. THE Controller_Node SHALL avere almeno 1024 MB di RAM allocata
2. THE Worker_Node SHALL avere almeno 1024 MB di RAM allocata
3. THE Controller_Node SHALL avere almeno 1 CPU allocata
4. THE Worker_Node SHALL avere almeno 1 CPU allocata
5. THE Vagrant_Environment SHALL verificare la disponibilità di risorse prima di creare le VM

### Requirement 3

**User Story:** Come utente, voglio che il controller node installi K3s in modalità server automaticamente, così da avere il control plane pronto senza intervento manuale.

#### Acceptance Criteria

1. WHEN il Controller_Node viene provisionato, THE Controller_Node SHALL installare K3s in modalità server
2. THE Controller_Node SHALL configurare K3s con node-ip 192.168.56.110
3. WHEN l'interfaccia di rete è rilevata, THE Controller_Node SHALL configurare Flannel_CNI con l'interfaccia corretta
4. THE Controller_Node SHALL configurare kubeconfig con permessi di lettura per l'utente vagrant
5. WHEN K3s è installato, THE Controller_Node SHALL essere nello stato "Ready"

### Requirement 4

**User Story:** Come utente, voglio che il controller node generi e condivida il token di autenticazione, così che il worker node possa joinare il cluster automaticamente.

#### Acceptance Criteria

1. WHEN K3s è installato sul Controller_Node, THE Controller_Node SHALL generare un Node_Token
2. THE Controller_Node SHALL salvare il Node_Token nella shared folder di Vagrant (/vagrant/token)
3. THE Node_Token SHALL essere leggibile dal Worker_Node tramite la shared folder
4. THE Controller_Node SHALL salvare il Kubeconfig nella shared folder (/vagrant/kubeconfig)
5. THE Kubeconfig SHALL avere l'IP del Controller_Node (192.168.56.110) invece di 127.0.0.1

### Requirement 5

**User Story:** Come utente, voglio che il worker node attenda il token e poi joini il cluster automaticamente, così da avere un cluster multi-node funzionante senza intervento manuale.

#### Acceptance Criteria

1. WHEN il Worker_Node viene provisionato, THE Worker_Node SHALL attendere la disponibilità del Node_Token
2. THE Worker_Node SHALL avere un timeout di 300 secondi per l'attesa del token
3. WHEN il Node_Token è disponibile, THE Worker_Node SHALL installare K3s in modalità agent
4. THE Worker_Node SHALL configurare K3s con node-ip 192.168.56.111 e K3S_URL https://192.168.56.110:6443
5. WHEN l'interfaccia di rete è rilevata, THE Worker_Node SHALL configurare Flannel_CNI con l'interfaccia corretta

### Requirement 6

**User Story:** Come utente, voglio che entrambi i nodi abbiano kubectl configurato, così da poter gestire il cluster da qualsiasi nodo.

#### Acceptance Criteria

1. THE Controller_Node SHALL avere kubectl configurato per l'utente vagrant
2. THE Worker_Node SHALL avere kubectl configurato per l'utente vagrant
3. WHEN l'utente esegue `kubectl get nodes` dal Controller_Node, THE K3s_Cluster SHALL mostrare entrambi i nodi
4. WHEN l'utente esegue `kubectl get nodes` dal Worker_Node, THE K3s_Cluster SHALL mostrare entrambi i nodi
5. THE Kubeconfig SHALL essere copiato in /home/vagrant/.kube/config su entrambi i nodi

### Requirement 7

**User Story:** Come utente, voglio verificare che il cluster sia funzionante, così da confermare che i nodi comunicano correttamente.

#### Acceptance Criteria

1. WHEN l'utente esegue `kubectl get nodes -o wide` da qualsiasi nodo, THE K3s_Cluster SHALL mostrare entrambi i nodi in stato "Ready"
2. THE Controller_Node SHALL avere il ruolo "control-plane,master"
3. THE Worker_Node SHALL avere il ruolo "<none>" o "worker"
4. THE K3s_Cluster SHALL mostrare gli IP interni corretti (192.168.56.110 e 192.168.56.111)
5. THE K3s_Cluster SHALL mostrare la versione di K3s installata

### Requirement 8

**User Story:** Come utente, voglio gestire il ciclo di vita del cluster con comandi Vagrant standard, così da poter avviare, fermare e distruggere l'ambiente facilmente.

#### Acceptance Criteria

1. WHEN l'utente esegue `vagrant halt` nella directory p1, THE Vagrant_Environment SHALL fermare entrambe le VM correttamente
2. WHEN l'utente esegue `vagrant up` dopo un halt, THE Vagrant_Environment SHALL riavviare entrambe le VM con K3s funzionante
3. WHEN l'utente esegue `vagrant destroy` nella directory p1, THE Vagrant_Environment SHALL rimuovere completamente entrambe le VM
4. WHEN l'utente esegue `vagrant ssh lotrapanS`, THE Vagrant_Environment SHALL aprire una sessione SSH sul Controller_Node
5. WHEN l'utente esegue `vagrant ssh lotrapanSW`, THE Vagrant_Environment SHALL aprire una sessione SSH sul Worker_Node

### Requirement 9

**User Story:** Come utente, voglio che il sistema gestisca automaticamente la risoluzione dei nomi, così che i nodi possano comunicare usando gli hostname.

#### Acceptance Criteria

1. THE Controller_Node SHALL avere "192.168.56.110 lotrapanS" nel file /etc/hosts
2. THE Controller_Node SHALL avere "192.168.56.111 lotrapanSW" nel file /etc/hosts
3. THE Worker_Node SHALL avere "192.168.56.110 lotrapanS" nel file /etc/hosts
4. THE Worker_Node SHALL avere "192.168.56.111 lotrapanSW" nel file /etc/hosts
5. WHEN un nodo esegue `ping lotrapanS` o `ping lotrapanSW`, THE Private_Network SHALL risolvere correttamente gli hostname

### Requirement 10

**User Story:** Come utente, voglio che il sistema rilevi automaticamente l'interfaccia di rete corretta, così da evitare problemi di configurazione Flannel.

#### Acceptance Criteria

1. WHEN lo script di provisioning viene eseguito, THE Controller_Node SHALL rilevare l'interfaccia di rete associata all'IP 192.168.56.110
2. WHEN lo script di provisioning viene eseguito, THE Worker_Node SHALL rilevare l'interfaccia di rete associata all'IP 192.168.56.111
3. WHEN l'interfaccia è rilevata, THE K3s_Cluster SHALL configurare Flannel_CNI con il flag --flannel-iface
4. WHEN l'interfaccia non è rilevata, THE K3s_Cluster SHALL usare la configurazione di default senza --flannel-iface
5. THE K3s_Cluster SHALL loggare quale interfaccia viene usata durante il provisioning
