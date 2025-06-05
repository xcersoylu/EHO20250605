  METHOD fill_json.
    TYPES : BEGIN OF ty_hesap,
              hesapno TYPE string,
            END OF ty_hesap,
            BEGIN OF ty_netbankpacket,
              packettype      TYPE string,
              hesaplar        TYPE ty_hesap,
              baslangictarihi TYPE string,
              bitistarihi     TYPE string,
            END OF ty_netbankpacket.
    DATA ls_json TYPE ty_netbankpacket.
    ls_json = VALUE #( packettype = 'HesapHareketleri'
                       hesaplar-hesapno = ms_bankpass-iban
                       baslangictarihi = mv_startdate
                       bitistarihi = mv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.