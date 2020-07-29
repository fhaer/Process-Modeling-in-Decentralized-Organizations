pragma solidity ^0.5.3;

contract GlobalContract {

    uint16 public nObjects;
    uint16 public nRelations;
    uint16 public nPeers;
    uint16 public nCollaborations;

    // Zuordnung: UUID Objekt -> Objekt
    mapping(bytes16 => Object) public knownObjects;

    // Zuordnung: ID relationID -> Beziehung
    mapping(uint16 => Relation) public knownRelations;

    // Zuordnung: ID peerID -> Peer
    mapping(uint16 => Peer) public peers;

    // Zuordnung: Adresse Peer -> Array zugeordneter Objekte
    mapping(address => bytes16[]) public objectMap;

    // Zuordnung: ID collaborationID -> Kooperation
    mapping(uint16 => Collaboration) public knownCollaborations;
    
    // Zuordnung: ID commitProcedureID -> Two-Phase-Commit-Verfahren
    mapping(uint16 => CommitProcedure) public commitProcedures;
    
    struct Object {
        // Objekt-ID  (sequenziell, ID > 0)
        uint16 objectID;
        // Peer-Zuordnung
        uint16 peerID;
        // Name
        bytes32 name;
        // objektspezifischer Smart Contract
        address objectSpecificContract;
        // ID der Kooperation
        uint16 collaborationID;
        // ID des laufenden Commit-Verfahrens
        uint16 commitProcedureID;
    }

    struct Relation {
        bytes16 sourceObject;
        bytes16 targetObject;
        bytes16 uuid;
        bytes32 name;
        RelationType relType;
    }

    enum RelationType { ZRelation, RRelation, LRelation }

    struct Peer {
        // Name
        bytes32 name;
        // Peer-Adresse
        address peer;
        // Versionsgraph URI (privater Prozess)
        bytes32 versiongraphAddressURI;
    }

    struct Collaboration {
        // Anzahl kooperierender Objekte
        uint16 nObjects;
        // Modell-Hash-Wert
        bytes32 modelHashValue;
        // ID des laufenden Two-Phase-Commit-Verfahrens
        uint16 commitProcedureID;
        // Versionsgraph URI (oeffentlicher Prozess)
        bytes32 versiongraphAddressURI;
    }

    struct CommitProcedure {
        // Ausfuehrungszustand des Commit-Verfahrens
        CommitProcedureState state;
        // Ergebnis des Commit-Verfahrens
        CommitProcedureResult result;
        // Anzahl Votes des Commit-Verfahrens
        uint16 nVotes;
        // Modell-Hash-Wert des laufenden Commit-Verfahrens
        bytes32 modelHashValue;
    }
    
    enum CommitProcedureState { Init, Wait }
    enum CommitProcedureResult { Abort, Commit }
                                 
    // Zuordnen des uebergebenen Objekts zum Peer des Absenders der Transaktion
    function assignObject(bytes16 object, bytes32 name) public {
        // Existierende Zuordnung nicht ueberschreiben
        if (knownObjects[object].peerID != 0) {
            return;
        }
        // Peer-ID vergeben oder ermitteln
        uint16 peerID;
        if (objectMap[msg.sender].length == 0) {
            // Peer-ID vergeben
            peerID = ++nPeers;
            peers[peerID].peer = msg.sender;
            peers[peerID].name = name;
        } else {
            // Peer-ID ermitteln
            bytes16 existingObject = objectMap[msg.sender][0];
            peerID = knownObjects[existingObject].peerID;
        }
        // Objekt-ID und -Name vergeben
        uint16 objectID = ++nObjects;
        knownObjects[object].objectID = objectID;
        knownObjects[object].name = name;
        // Zuordnung
        knownObjects[object].peerID = peerID;
        objectMap[msg.sender].push(object);
        emit ObjectAssigned(objectID, object, name, msg.sender);
    }

    // Event bei Zuordnung eines Objekts
    event ObjectAssigned(uint16 indexed objectID, bytes16 object, bytes32 name, address peer);

    // Prueft, ob das angegebene Objekt registriert ist
    function objectExists(bytes16 object) public view returns (bool) {
        if (knownObjects[object].objectID > 0) {
            return true;
        }
        return false;
    }
                                        
    // Zuordnen eines objektspezifischen Smart Contracts zu einem Objekt
    function assignObjectSpecificContract(address objectSpecificContract, bytes16 object) public {
        // Absender ueberpruefen
        uint16 peerID = knownObjects[object].peerID;
        if (peers[peerID].peer != msg.sender) {
            return;
        }
        knownObjects[object].objectSpecificContract = objectSpecificContract;
        emit ObjectSpecificContractAssigned(knownObjects[object].objectID, object);
    }

    // Event bei AEnderung des Objekt-Names
    event ObjectSpecificContractAssigned(uint16 indexed objectID, bytes16 object);

    /// @notice Setzen des Peer-Names
    /// @param name Name des Peers
    function setPeerName(bytes32 name) public {
        if (objectMap[msg.sender].length > 0) {
            bytes16 existingObject = objectMap[msg.sender][0];
            uint16 peerID = knownObjects[existingObject].peerID;
            // Festlegung moeglich, sofern der Aufrufer die Adresse des Peers besitzt
            if (peers[peerID].peer != msg.sender) {
                return;
            }
            peers[peerID].name = name;
        }
    }

    /// @notice Setzen des Peer-Names
    /// @param name Name des Peers
    function setObjectName(bytes16 object, bytes32 name) public {
        uint16 peerID = knownObjects[object].peerID;
        if (peers[peerID].peer == msg.sender) {
            knownObjects[object].name = name;
            emit ObjectNameChanged(knownObjects[object].objectID, object, name);
        }
    }
    
    // Event bei AEnderung des Objekt-Names
    event ObjectNameChanged(uint16 indexed objectID, bytes16 object, bytes32 name);

    /// @notice Setzen des Peer-Names
    /// @param name Name des Peers
    function setRelationName(uint16 relationID, bytes32 name) public {
        bytes16 sourceObj = knownRelations[relationID].sourceObject;
        uint16 peerID = knownObjects[sourceObj].peerID;
        if (peers[peerID].peer == msg.sender) {
            bytes16 uuid = knownRelations[relationID].uuid;
            knownRelations[relationID].name = name;
            emit RelationNameChanged(relationID, uuid, name);
        }
    }

    // Event bei AEnderung des Objekt-Names
    event RelationNameChanged(uint16 indexed relationID, bytes16 uuid, bytes32 newName);

    /// @notice Setzen des Versionsgraphen
    /// @param versiongraphAddressURI URI des Versionsgraphen
    function setPeerVersionGraph(bytes32 versiongraphAddressURI) public {
        if (objectMap[msg.sender].length > 0) {
            bytes16 existingObject = objectMap[msg.sender][0];
            uint16 peerID = knownObjects[existingObject].peerID;
            // Festlegung moeglich, sofern der Aufrufer die Adresse des Peers besitzt
            if (peers[peerID].peer != msg.sender) {
                return;
            }
            peers[peerID].versiongraphAddressURI = versiongraphAddressURI;
        }
    }

    /// @notice Ermitteln der Objekte eines Peers
    /// @param peer Adresse des Peers
    /// @return Array der ObjektIDs des Peers
    function objMap(address peer) public view returns (bytes16[] memory objectIDs) {
        return objectMap[peer];
    }
    
    // Beziehung hinzufuegen
    function addRelation(bytes16 sourceObject, bytes16 targetObject, bytes16 uuid, bytes32 name, RelationType relType) public {
        uint16 peerID = knownObjects[sourceObject].peerID;
        if (peers[peerID].peer != msg.sender) {
            return;
        }
        // Existenz der Objekte ueberpruefen
        if (knownObjects[sourceObject].objectID == 0 || 
            knownObjects[targetObject].objectID == 0 ) {
            return;
        }
        // Beziehung registrieren
        uint16 relationID = ++nRelations;
        knownRelations[relationID].sourceObject = sourceObject;
        knownRelations[relationID].targetObject = targetObject;
        knownRelations[relationID].uuid = uuid;
        knownRelations[relationID].name = name;
        knownRelations[relationID].relType = relType;
    }

    /// @notice Hinzufuegen eines Objekts zu einer Collaboration, sofern das Objekt Teil einer Z-R-Beziehung ist
    /// @param object Objekt, das zur Collaboration hinzugefuegt werden soll
    /// @param sourceObject Start-Objekt einer bestehenden Z-R-Beziehung
    /// @param targetObject Ziel-Objekt einer bestehenden Z-R-Beziehung
    /// @param zRelationID ID der Z-Beziehung
    /// @param rRelationID ID der R-Beziehung
    function addCollaboration(bytes16 object, bytes16 sourceObject, bytes16 targetObject, uint16 zRelationID, uint16 rRelationID) public {
        uint16 peerID = knownObjects[object].peerID;
        if (peers[peerID].peer != msg.sender) {
            return;
        }
        // Objekt bereits Teil einer Kooperation
        uint16 collaborationID = knownObjects[object].collaborationID;
        if (collaborationID > 0) {
            return;
        }

        // Bestimmung des in Beziehung stehenden Objekts
        bytes16 relatedObject = 0;
        if (object == sourceObject) {
            relatedObject = targetObject;
        } else if (object == targetObject) {
            relatedObject = sourceObject;
        }
        
        if (knownRelations[zRelationID].sourceObject == sourceObject && 
            knownRelations[zRelationID].targetObject == targetObject && 
            knownRelations[rRelationID].sourceObject == targetObject && 
            knownRelations[rRelationID].targetObject == sourceObject && 
            knownRelations[zRelationID].relType == RelationType.ZRelation && 
            knownRelations[rRelationID].relType == RelationType.RRelation) {

                // ID der Kooperation ermitteln oder vergeben
                if (knownObjects[relatedObject].collaborationID > 0) {
                    collaborationID = knownObjects[relatedObject].collaborationID;
                } else {
                    // Kooperation erstellen
                    collaborationID = ++nCollaborations;
                    // Versionsgraph URI auf initiierendes Peer setzen
                    knownCollaborations[collaborationID].versiongraphAddressURI = peers[peerID].versiongraphAddressURI;
                }
            
                // Kooperation beitreten
                knownObjects[object].collaborationID = collaborationID;
                knownCollaborations[collaborationID].nObjects++;
        }
    }

    /// @notice Einleiten eines globalen Commits
    /// @param hashValue Modell-Hash-Wert des uebergebenen Objekts
    /// @param object Objekt, von dem der Commit ausgeht
    function commit(bytes32 hashValue, bytes16 object) public {
        // Transaktionsabsender ueberpruefen
        uint16 peerID = knownObjects[object].peerID;
        if (peers[peerID].peer != msg.sender) {
            return;
        }
        uint16 coID = knownObjects[object].collaborationID;
        uint16 cpID = knownCollaborations[coID].commitProcedureID;
        // Commit bei Vorliegen des Zustands Init beginnen
        if (commitProcedures[cpID].state == CommitProcedureState.Init) {
            cpID++;
            commitProcedures[cpID].state = CommitProcedureState.Wait;
            commitProcedures[cpID].modelHashValue = hashValue;
            knownCollaborations[coID].commitProcedureID = cpID;
            emit VoteRequest(coID, cpID, object);
        }
    }

    // Event zur UEbermittlung der Vote-Request-Nachricht
    event VoteRequest(uint16 indexed collaborationID, uint16 commitProcedureID, bytes16 object);

    /// @notice Abstimmung ueber die Durchfuehrung oder den Abbruch des laufenden Commits
    /// @param object betriebliches Objekt
    /// @param voteCommit TRUE: Vote Commit, FALSE: Vote Abort
    function voteGlobalCommit(bytes16 object, bool voteCommit) public {
        uint16 peerID = knownObjects[object].peerID;
        if (peers[peerID].peer != msg.sender) {
            return;
        }
        uint16 collaborationID = knownObjects[object].collaborationID;
        uint16 commitProcedureID = knownCollaborations[collaborationID].commitProcedureID;
        if (commitProcedures[commitProcedureID].state == CommitProcedureState.Wait && 
            knownObjects[object].commitProcedureID < commitProcedureID) {
                commitProcedures[commitProcedureID].nVotes++;
                knownObjects[object].commitProcedureID = commitProcedureID;
                uint16 nCollabObjects = knownCollaborations[collaborationID].nObjects;
                uint16 nVotes = commitProcedures[commitProcedureID].nVotes;
                if (!voteCommit) {
                    abortGlobalCommit(commitProcedureID);
                } else if (voteCommit && nCollabObjects == nVotes) {
                    executeGlobalCommit(commitProcedureID, collaborationID);
                }
        }
    }
    
    event GlobalAbort(uint16 indexed commitProcedureID);

    /// @notice Abbruch des laufenden Commits
    /// @param commitProcedureID ID des Commits
    function abortGlobalCommit(uint16 commitProcedureID) internal {
        emit GlobalAbort(commitProcedureID);
        commitProcedures[commitProcedureID].result = CommitProcedureResult.Abort;
        commitProcedures[commitProcedureID].state = CommitProcedureState.Init;
    }

    event GlobalCommit(uint16 indexed commitProcedureID, uint16 collaborationID);
    
    /// @notice Durchfuehrung und Abschluss des laufenden Commits
    /// @param commitProcedureID ID des Commits
    /// @param collaborationID ID der Kooperation des Commits
    function executeGlobalCommit(uint16 commitProcedureID, uint16 collaborationID) internal {          
        commitProcedures[commitProcedureID].result = CommitProcedureResult.Commit;
        commitProcedures[commitProcedureID].state = CommitProcedureState.Init;                
        knownCollaborations[collaborationID].modelHashValue = 
        commitProcedures[commitProcedureID].modelHashValue;
        emit GlobalCommit(commitProcedureID, collaborationID);
    }

    /// @notice Rueckgabe der commitProcedureID des letzten erfolgreichen Commits
    /// @param object Objekt, das an dem Commit beteiligt war
    /// @return ID des Commits (commitProcedureID)
    function getCommitProcedureID(bytes16 object) public view returns (uint16) {
        uint16 id = knownObjects[object].commitProcedureID;
        while (id >= 0 && commitProcedures[id].result != CommitProcedureResult.Commit) {
            id--;
        }
        return id;
    }
}
