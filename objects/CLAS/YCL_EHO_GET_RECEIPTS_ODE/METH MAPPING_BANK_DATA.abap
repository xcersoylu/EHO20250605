  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareketler,
              tarih          TYPE string,
              saat           TYPE string,
              sirano         TYPE string,
              harekettutari  TYPE string,
              sonbakiye      TYPE string,
              aciklamalar    TYPE string,
              musterino      TYPE string,
              islemkodu      TYPE string,
              referansno     TYPE string,
              karsihesapvkno TYPE string,
              dekontno       TYPE string,
              ekbilgi1       TYPE string,
              ekbilgi2       TYPE string,
              ekbilgi3       TYPE string,
              ekbilgi4       TYPE string,
            END OF ty_hareketler,
            tt_hareketler TYPE TABLE OF ty_hareketler WITH DEFAULT KEY,
            BEGIN OF ty_hareketdetay,
              hesaphareketidetail TYPE tt_hareketler,
            END OF ty_hareketdetay,
            BEGIN OF ty_hesap,
              hesapturu                   TYPE string,
              hesapadi                    TYPE string,
              musterino                   TYPE string,
              hesapcinsi                  TYPE string,
              hesapnumarasi               TYPE string,
              subenumarasi                TYPE string,
              subeadi                     TYPE string,
              acilistarihi                TYPE string,
              sonharekettarihi            TYPE string,
              bakiye                      TYPE string,
              blokemeblag                 TYPE string,
              kullanilabilirbakiye        TYPE string,
              kredilimiti                 TYPE string,
              kredilikullanilabilirbakiye TYPE string,
              vadetarihi                  TYPE string,
              faizorani                   TYPE string,
            END OF ty_hesap,
            BEGIN OF ty_hesapdetay,
              hesaptanimi      TYPE ty_hesap,
              hesaphareketleri TYPE ty_hareketdetay,
            END OF ty_hesapdetay,
            tt_hesapdetay TYPE TABLE OF ty_hesapdetay WITH DEFAULT KEY,
            BEGIN OF ty_bankahesaplar,
              systarih           TYPE string,
              syssaat            TYPE string,
              hatakodu           TYPE string,
              hataaciklama       TYPE string,
              hesapbilgisidetail TYPE tt_hesapdetay,
            END OF ty_bankahesaplar.
    DATA ls_json_response TYPE ty_bankahesaplar.
    DATA lv_json TYPE string.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    lv_json = iv_json.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).
    READ TABLE ls_json_response-hesapbilgisidetail INTO DATA(ls_hesap) WITH KEY hesaptanimi-hesapcinsi = ms_bankpass-bankaccount.
    IF sy-subrc = 0.
      LOOP AT ls_hesap-hesaphareketleri-hesaphareketidetail INTO DATA(ls_hareket).

        lv_sequence_no += 1.
        ls_offline_data-companycode =  ms_bankpass-companycode.
        ls_offline_data-glaccount   =  ms_bankpass-glaccount.
        ls_offline_data-sequence_no =  lv_sequence_no.
        ls_offline_data-description = ls_hareket-aciklamalar.

        IF ls_hareket-harekettutari > 0.
          ls_offline_data-debit_credit = 'A'.
          ls_offline_data-debtor_vkn = ls_hareket-karsihesapvkno.
        ENDIF.
        IF ls_hareket-harekettutari < 0.
          ls_offline_data-debit_credit = 'B'.
          ls_offline_data-payee_vkn = ls_hareket-karsihesapvkno.

          SHIFT ls_hareket-harekettutari BY 1 PLACES LEFT.
        ENDIF.

        IF ls_offline_data-debit_credit = 'B'.
          ls_offline_data-current_balance          = ls_hareket-sonbakiye - ls_hareket-harekettutari.
        ELSE.
          ls_offline_data-current_balance          = ls_hareket-sonbakiye + ls_hareket-harekettutari.
        ENDIF.

        ls_offline_data-amount                 = ls_hareket-harekettutari.
        ls_offline_data-receipt_no             = ls_hareket-dekontno.

        CONCATENATE ls_hareket-tarih+6(4)
                    ls_hareket-tarih+3(2)
                    ls_hareket-tarih+0(2)
               INTO ls_offline_data-physical_operation_date.

        CONCATENATE ls_hareket-saat+0(2)
                    ls_hareket-saat+3(2)
                    ls_hareket-saat+6(2)
               INTO ls_offline_data-time.

        CONCATENATE ls_hareket-tarih+6(4)
                    ls_hareket-tarih+3(2)
                    ls_hareket-tarih+0(2)
               INTO ls_offline_data-valor.

        ls_offline_data-sender_iban      = ls_hareket-referansno.
        ls_offline_data-transaction_type = ls_hareket-islemkodu.

        APPEND ls_offline_data TO et_bank_data.
        CLEAR ls_offline_data.
      ENDLOOP.
      IF sy-subrc = 0.
        DATA(lt_bank_data) = et_bank_data.
        SORT lt_bank_data BY physical_operation_date time ASCENDING.
        READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
        IF ls_bank_data-debit_credit = 'B'.
          lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
        ELSE.
          lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
        ENDIF.
        SORT lt_bank_data BY physical_operation_date time ASCENDING.
        READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
        lv_closing_balance = ls_bank_data-current_balance.
      ELSE.
        lv_opening_balance  = lv_closing_balance = ls_hesap-hesaptanimi-bakiye.
      ENDIF.
      APPEND VALUE #( companycode = ms_bankpass-companycode
                      glaccount = ms_bankpass-glaccount
                      valid_from = mv_startdate
                      account_no = ms_bankpass-bankaccount
                      branch_no = ms_bankpass-branch_code
                      branch_name_description = ycl_eho_utils=>get_branch_name(
                                                  iv_companycode = ms_bankpass-companycode
                                                  iv_bank_code   = ms_bankpass-bank_code
                                                  iv_branch_code = ms_bankpass-branch_code
                                                )
                      currency = ms_bankpass-currency
                      opening_balance =  lv_opening_balance
                      closing_balance = lv_closing_balance
                      bank_id =  ''
                      account_id = ''
                      bank_code =   ms_bankpass-bank_code
      ) TO  et_bank_balance.

    ENDIF.
  ENDMETHOD.