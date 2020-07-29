pragma solidity ^0.5.3;

contract ObjectSpecificContract {

    // Objekt
    bytes16 public object;          
    // Peer-Zuordnung  
    address public peer;              

    // Zuordnung: Objekt-Zerlegungsprodukt -> Versions-Hash-Werte
    mapping(bytes16 => VersionHashValues) public versionHashValues;
    
    // Datentyp VersionHashValues zur Speicherung von Hash-Werten je Version
    struct VersionHashValues {
       uint16 nVersions;                            // Anzahl Versionen
       mapping(uint16 => bytes32) hashValues;       // Hash-Werte
       mapping(uint16 => uint16) commitProcedureID; // Commit-IDs
    }

    /// @notice Einleiten eines lokalen Commits
    /// @param hashValue Modell-Hash-Wert des uebergebenen Objekts
    /// @param object Objekt, von dem der Commit ausgeht
    function commit(bytes32 hashValue, bytes16 object) public {
       // Transaktionsabsender ueberpruefen
       if (msg.sender != peer) {
           return;
       }
       // Sequenz-ID der Version (0 < versionSequenceID <= nVersions)
       uint16 versionSequenceID = ++versionHashValues[object].nVersions;
       // ID des letzten globalen Commits ermitteln
       uint16 commitProcedureID = GlobalContract(globalContract).getCommitProcedureID(object);
       // Zuweisung Versions-Hash-Wert
       VersionHashValues storage vhv = versionHashValues[object];
       vhv.hashValues[versionSequenceID] = hashValue;
       vhv.commitProcedureID[versionSequenceID] = commitProcedureID;
    }

    // Zuordnung: T-Event-ID -> Transaktionsabsender (zulaessige Peer-Adresse)
    mapping (bytes16 => address) public transactionSenders;

    // Zuordnung: instanceID => Instanz
    mapping (bytes16 => Instance) public knownInstances;

    // Zuordnung: taskEventAssignmentID => Event-Token-Zuordnung
    mapping (uint16 => TaskEventAssignment) public taskEventAssignments;

    // Anzahl von Instanz-Ereignis-Zuordnungen
    uint16 public nTaskEventAssignments;  

    // Datentyp Instanz
    struct Instance {
        bytes16 objectID;
        bytes16 instanceID;
        uint16 taskEventAssignmentID;
    }

    // Datentyp Event-Zuordnung
    struct TaskEventAssignment {
        bytes16 taskEventID;
        bytes32 versionID;
    }

    address public globalContract;  // Adresse des globalen Smart Contracts

    // Konstruktor: initiale Peer-Zuordnung, Zuordnung Global Contract
    constructor(address globalContractAddress, bytes16 objectUUID) public {
        peer = msg.sender;
        globalContract = globalContractAddress;
        object = objectUUID;
    }

    /// @notice Zuordnung des repraesentierten Objekts
    /// @param objectID Objekt
    function setObject(bytes16 objectID) public {
        if (msg.sender != peer) {
            return;
        }
        object = objectID;
    }

    function getNVersionHashValues(bytes16 objectID) public view returns (uint16) {
        return versionHashValues[objectID].nVersions;
    }

    function getVersionHashValue(bytes16 objectID, uint16 versionNr) public view returns (bytes32) {
        return versionHashValues[objectID].hashValues[versionNr];
    }

    function getVersionCommitProcedureID(bytes16 objectID, uint16 versionNr) public view returns (uint16) {
        return versionHashValues[objectID].commitProcedureID[versionNr];
    }
    
    // Letzten bekannten Hash-Wert des uebergebenen Objekts zurueckgeben
    function getLatestHashValue(bytes16 objectID) public view returns (bytes32) {
        uint16 versionSequenceID = versionHashValues[objectID].nVersions;
        VersionHashValues storage vhs = versionHashValues[objectID];
        return vhs.hashValues[versionSequenceID];
    }

    // Hinterlegen des zulaessigen Absenders einer Transaktion
    function addTransactionSender(bytes16 tTaskEventID, address transactionSender) public {
        if (msg.sender != peer) {
            return;
        }
        transactionSenders[tTaskEventID] = transactionSender;
    }

    /// @notice O-Ereignis-Ausloesung per UEberfuehrung des Tokens tokenID in oTaskEventID
    /// @param oTaskEventID UUID des auszuloesenden Transaktionsereignisses
    /// @param tokenID UUID des zu transferierenden Tokens
    /// @param instanceID UUID der Instanz
    /// @param objectID UUID des instanziierenden Objekts
    /// @param versionID Hash-Wert des Prozessmodells
    function triggerTaskExecutionEvent(bytes16 oTaskEventID, bytes16 instanceID, bytes16 objectID, bytes32 versionID) public {
        if (msg.sender != peer) {
            return;
        }
        uint16 taskEventAssignmentID = knownInstances[instanceID].taskEventAssignmentID;
        if (taskEventAssignmentID < 1) {
            taskEventAssignmentID = ++nTaskEventAssignments;
            knownInstances[instanceID].objectID = objectID;
            knownInstances[instanceID].instanceID = instanceID;
            knownInstances[instanceID].taskEventAssignmentID = taskEventAssignmentID;
        }
        taskEventAssignments[taskEventAssignmentID].taskEventID = oTaskEventID;
        taskEventAssignments[taskEventAssignmentID].versionID = versionID;
        // Nachricht zur Ausloesung des Ereignisses per Event
        emit ObjectTaskEvent(oTaskEventID, instanceID, objectID, versionID);
    }
    
    /// @notice T-Ereignis-Ausloesung: UEbergang tokenID zu tTaskEventID
    /// @param tTaskEventID UUID des auszuloesenden Transaktionsereignisses
    /// @param instanceID UUID der Instanz
    /// @param objectID UUID des instanziierenden Objekts
    /// @param versionID Hash-Wert der instanziierten Version des Prozesses
    function triggerTransactionEvent(bytes16 tTaskEventID, bytes16 instanceID, bytes16 objectID, bytes32 versionID) public {
        // UEberpruefen des Transaktionsabsenders
        if (msg.sender != peer || msg.sender != transactionSenders[tTaskEventID]) {
            return;
        }
        uint16 taskEventAssignmentID = knownInstances[instanceID].taskEventAssignmentID;
        if (taskEventAssignmentID < 1) {
            taskEventAssignmentID = ++nTaskEventAssignments;
            knownInstances[instanceID].objectID = objectID;
            knownInstances[instanceID].instanceID = instanceID;
            knownInstances[instanceID].taskEventAssignmentID = taskEventAssignmentID;
        }
        taskEventAssignments[taskEventAssignmentID].taskEventID = tTaskEventID;
        taskEventAssignments[taskEventAssignmentID].versionID = versionID;
        // Nachricht zur Ausloesung des Ereignisses per Event
        emit TransactionTaskEvent(tTaskEventID, instanceID, objectID, versionID);
    }

    // Events zur Ausloesung von Ereignis-UEbergaengen
    event TransactionTaskEvent(bytes16 indexed taskEventID, bytes16 instanceID, bytes16 objectID, bytes32 versionID);
    event ObjectTaskEvent(bytes16 indexed taskEventID, bytes16 instanceID, bytes16 objectID, bytes32 versionID);

    function resetState() public {
        if (msg.sender != peer) {
            return;
        }
        nTaskEventAssignments = 0;
    }
}


// Global Contract Interface fuer Aufrufe des globalen Smart Contracts
contract GlobalContract {
    function getCommitProcedureID(bytes16 object) public returns (uint16);
}
