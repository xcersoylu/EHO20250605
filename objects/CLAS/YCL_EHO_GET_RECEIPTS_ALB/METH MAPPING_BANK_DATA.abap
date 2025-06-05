  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hesaphareket,
              tarih              TYPE string,
              saat               TYPE string,
              aciklama           TYPE string,
              borcalacak         TYPE string,
              islemtutari        TYPE string,
              bakiye             TYPE string,
              karsihesapiban     TYPE string,
              karsihesaptcknvkn  TYPE string,
              fisno              TYPE string,
              code               TYPE string,
              seqnumber          TYPE string,
              branchcode         TYPE string,
              islemsonrasibakiye TYPE string,
              muhrefno           TYPE string,
            END OF ty_hesaphareket,
            tt_hesaphareket TYPE TABLE OF ty_hesaphareket WITH DEFAULT KEY,
            BEGIN OF ty_hesap,
              musterino    TYPE string,
              hesapno      TYPE string,
              hesapiban    TYPE string,
              hesaphareket TYPE tt_hesaphareket,
            END OF ty_hesap,
            tt_hesap type table of ty_hesap with DEFAULT KEY,
            BEGIN OF ty_hesaphareketleri,
            hesaphareketleri type tt_hesap,
            END OF ty_hesaphareketleri.
    DATA ls_json_response TYPE ty_hesaphareketleri.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_Response-hesaphareketleri into data(ls_hesaphareketleri) WITH key hesapiban = ms_bankpass-iban.
    LOOP AT ls_hesaphareketleri-hesaphareket into DATA(ls_hesaphareketi).
      lv_sequence_no += 1.
      ls_offline_data-companycode =  ms_bankpass-companycode.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.
      ls_offline_data-sequence_no =  lv_sequence_no.
      ls_offline_data-amount                 = ls_hesaphareketi-islemtutari.
      ls_offline_data-description            = ls_hesaphareketi-aciklama.
      ls_offline_data-debit_credit           = ls_hesaphareketi-borcalacak.
      IF ls_hesaphareketi-borcalacak = 'B'.
        ls_offline_data-payee_vkn = ls_hesaphareketi-karsihesaptcknvkn.
      ENDIF.
      IF ls_hesaphareketi-borcalacak = 'A'.
        ls_offline_data-debtor_vkn = ls_hesaphareketi-karsihesaptcknvkn.
      ENDIF.
      ls_offline_data-current_balance         = ls_hesaphareketi-islemsonrasibakiye.
      ls_offline_data-receipt_no              = ls_hesaphareketi-fisno.
      ls_offline_data-physical_operation_date = ls_hesaphareketi-tarih.
      ls_offline_data-time                    = ls_hesaphareketi-saat.
      ls_offline_data-valor                   = ls_hesaphareketi-tarih.
      ls_offline_data-sender_iban             = ls_hesaphareketi-karsihesapiban.
      ls_offline_data-transaction_type        = ls_hesaphareketi-code.
      ls_offline_data-sender_branch           = ls_hesaphareketi-branchcode.
      APPEND ls_offline_data TO et_bank_Data.
      CLEAr ls_offline_Data.
    ENDLOOP.
" #TODO hesap detayları için ayrıca servis çağırılacak!!!
***    IF sy-subrc = 0.
***      DATA(lt_bank_data) = et_bank_data.
***      SORT lt_bank_data BY physical_operation_date time ASCENDING.
***      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
***      IF ls_bank_data-debit_credit = 'B'.
***        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
***      ELSE.
***        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
***      ENDIF.
***      SORT lt_bank_data BY physical_operation_date time ASCENDING.
***      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
***      lv_closing_balance = ls_bank_data-current_balance.
***    ELSE.
***      lv_opening_balance  = lv_closing_balance = ls_hesaphareketleri-
***    ENDIF.

    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount   = ms_bankpass-glaccount
                    valid_from  = mv_startdate
                    account_no  = ms_bankpass-bankaccount
                    branch_no   = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  lv_opening_balance
                    closing_balance =  lv_closing_balance
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.
  ENDMETHOD.