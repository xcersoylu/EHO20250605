  METHOD fill_json.
    TYPES : BEGIN OF ty_getaccountstatement,
              extuname      TYPE string,
              extupassword  TYPE string,
              accountnumber TYPE string,
              accountsuffix TYPE string,
              begindate     TYPE string,
              enddate       TYPE string,
            END OF ty_getaccountstatement.
    DATA ls_json TYPE ty_getaccountstatement.
    DATA(lv_startdate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2).

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2).
    ls_json = VALUE #( extuname = ms_bankpass-service_user
                       extupassword = ms_bankpass-service_password
                       accountnumber = ms_bankpass-bankaccount
                       accountsuffix = ms_bankpass-suffix
                       begindate = lv_startdate
                       enddate = lv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json ).
  ENDMETHOD.