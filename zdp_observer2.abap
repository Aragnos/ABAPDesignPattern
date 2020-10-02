
*&---------------------------------------------------------------------*
*& Report  ZDP_OBSERVER2
*&
*&---------------------------------------------------------------------*
*& A variant of the observer pattern without the use of events.
*&
*&---------------------------------------------------------------------*
PROGRAM zdp_observer2.

INTERFACE main_process_observer.
  METHODS notify IMPORTING new_state TYPE char1.
ENDINTERFACE.

CLASS main_process DEFINITION.
  PUBLIC SECTION.
    METHODS: set_state IMPORTING iv_state TYPE char1.
    METHODS: subscribe IMPORTING io_observer TYPE REF TO main_process_observer.
    METHODS: unsubscribe IMPORTING io_observer TYPE REF TO main_process_observer.
  PRIVATE SECTION.
    METHODS: notify.
    DATA: current_state TYPE char1.
    DATA: observers TYPE TABLE OF REF TO main_process_observer.
ENDCLASS.

CLASS main_process IMPLEMENTATION.
  METHOD set_state.
    current_state = iv_state.
    SKIP 2.
    WRITE: / 'Main Process new state', current_state.
    me->notify( ).
  ENDMETHOD.
  
  METHOD subscribe.
    "Do not include the same observer more than once.
    IF io_observer IS NOT BOUND.
      "Raise Exception
      RETURN.
    ENDIF.
    TRY.
      DATA(tmp_obs) = observers[ table_line = io_observer ].
    CATCH cx_sy_itab_line_not_found.
      APPEND io_observer to observers.
    ENDTRY.
  ENDMETHOD.
  
  METHOD unsubscribe.
    "As we only allow each observer to reside one time in the internal table, the delete statement does not need to loop through the itab.
    IF io_observer IS NOT BOUND.
      "Raise Exception
      RETURN.
    ENDIF.
    DELETE TABLE observers FROM io_observer.
  ENDMETHOD.
  
  METHOD notify.
    LOOP AT observers ASSIGNING FIELD-SYMBOL(<observer>)
      <observer>->notify( current_state ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS myfunction DEFINITION ABSTRACT.
  PUBLIC SECTION.
    INTERFACES main_process_observer.
ENDCLASS.

CLASS myalv DEFINITION INHERITING FROM myfunction.
  PUBLIC SECTION.
    METHODS: main_process_observer~notify REDEFINITION.
ENDCLASS.


CLASS myalv IMPLEMENTATION.
  METHOD main_process_observer~notify.
    WRITE: / 'New state in ALV processing', new_state.
  ENDMETHOD.
ENDCLASS.

CLASS mydb DEFINITION INHERITING FROM myfunction.
  PUBLIC SECTION.
    METHODS: main_process_observer~notify REDEFINITION.
ENDCLASS.

CLASS mydb IMPLEMENTATION.
  METHOD main_process_observer~notify.
    WRITE: / 'New State in DB processing', new_state.
  ENDMETHOD.
ENDCLASS.

CLASS main_app DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: run.
ENDCLASS.

CLASS main_app  IMPLEMENTATION.
  METHOD run.
    DATA: lo_process TYPE REF TO main_process.
    DATA: lo_alv TYPE REF TO myalv.
    DATA: lo_db TYPE REF TO mydb.

    CREATE OBJECT: lo_process,
                   lo_alv,
                   lo_db.
    
    lo_process->subscribe( lo_alv ).
    lo_process->subscribe( lo_db ).

    lo_process->set_state( 'A' ).
    lo_process->set_state( 'B' ).
    lo_process->set_state( 'C' ).
    
    "ALV wants to stay in the loop, but db has enough:
    lo_process->unsubscribe( lo_db ).
    
    "...
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  main_app=>run( ).
