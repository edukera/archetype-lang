// LIGO output generated by archetype 1.0.1

// contract: balance

// To generate origination storage string please execute the following command:
// ligo compile-storage balance.ligo main 'Unit'


type storage_type is nat
type action_getBalance is contract(nat)

type action is
  | GetBalance of action_getBalance
  | SetBalance of nat


function getBalance(const action : action_getBalance; const s_ : storage_type) : (list(operation) * storage_type) is
  begin
    var ops_ : list(operation) := (nil : list(operation));
    const op_ : operation = Tezos.transaction(s_, 0mutez, action);
    ops_ := cons(op_, ops_)
  end with (ops_, s_)

  function setBalance(const v : nat; const s_ : storage_type) : (list(operation) * storage_type) is
  begin
    s_ := v;
  end with ((nil : list(operation)), s_)

function main(const action : action ; const s_ : storage_type) : (list(operation) * storage_type) is
  block {skip} with
  case action of
  | GetBalance (a_) -> getBalance(a_, s_)
  | SetBalance (a_) -> setBalance(a_, s_)
  end


