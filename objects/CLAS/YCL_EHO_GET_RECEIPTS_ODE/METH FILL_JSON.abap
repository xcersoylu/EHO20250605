  METHOD fill_json.
    TYPES : BEGIN OF ty_generalassociationcoderep,
              associationcode TYPE string,
              usercode        TYPE string,
              password        TYPE string,
              startdate       TYPE string,
              enddate         TYPE string,
            END OF ty_generalassociationcoderep,
            BEGIN OF ty_json,
              generalassociationcoderep TYPE ty_generalassociationcoderep,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA(lv_startdate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2).

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2).
    ls_json-generalassociationcoderep = VALUE #( associationcode = ms_bankpass-service_user
                                                 usercode = ms_bankpass-service_user
                                                 password = ms_bankpass-service_password
                                                 startdate = lv_startdate
                                                 enddate = lv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.