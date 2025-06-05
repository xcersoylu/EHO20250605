  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_trnsdetails,
              amount               TYPE string,
              branchid             TYPE string,
              branchname           TYPE string,
              businesskey          TYPE string,
              channelid            TYPE string,
              credit               TYPE string,
              currentbalance       TYPE string,
              debit                TYPE string,
              description          TYPE string,
              fec                  TYPE string,
              fecname              TYPE string,
              iban                 TYPE string,
              resourcecode         TYPE string,
              senderidentitynumber TYPE string,
              swifttransactioncode TYPE string,
              systemdate           TYPE string,
              trandate             TYPE string,
              tranref              TYPE string,
              trantype             TYPE string,
              valuedate            TYPE string,
            END OF ty_trnsdetails,
            tt_trnsdetails TYPE TABLE OF ty_trnsdetails WITH DEFAULT KEY,
            BEGIN OF ty_blncdetails,
              beginamount TYPE string,
              endamount   TYPE string,
              fec         TYPE string,
              trandate    TYPE string,
            END OF ty_blncdetails,
            tt_blncdetails TYPE TABLE OF ty_blncdetails WITH DEFAULT KEY,
            BEGIN OF ty_accountcontract,
              accountnumber  TYPE string,
              accountsuffix  TYPE string,
              balance        TYPE string,
              productcode    TYPE string,
              balancedetails TYPE tt_blncdetails,
              details        TYPE tt_trnsdetails,
            END OF ty_accountcontract.
    DATA ls_json_response TYPE ty_accountcontract.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    SORT ls_json_response-details BY trandate DESCENDING.
    LOOP AT ls_json_response-details into data(ls_detail).
      CLEAR : ls_offline_data.

      lv_sequence_no += 1.
      ls_offline_data-companycode =  ms_bankpass-companycode.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.
      ls_offline_data-sequence_no =  lv_sequence_no.
      ls_offline_data-description = ls_detail-description.

      IF ls_detail-amount > 0.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-payee_vkn = ls_detail-senderidentitynumber.
      ENDIF.
      IF ls_detail-amount < 0.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-debtor_vkn = ls_detail-senderidentitynumber.
        SHIFT ls_detail-amount BY 1 PLACES LEFT.
      ENDIF.

      ls_offline_data-amount                 = ls_detail-amount.
      ls_offline_data-current_balance          = ls_detail-currentbalance.
      ls_offline_data-receipt_no             = ls_detail-businesskey.

      IF ls_detail-systemdate IS NOT INITIAL.
        CONCATENATE ls_detail-systemdate+0(4)
                    ls_detail-systemdate+5(2)
                    ls_detail-systemdate+8(2)
               INTO ls_offline_data-physical_operation_date.

        CONCATENATE ls_detail-systemdate+11(2)
                    ls_detail-systemdate+14(2)
                    ls_detail-systemdate+17(2)
               INTO ls_offline_data-time.
      ENDIF.

      CONCATENATE ls_detail-trandate+11(2)
                  ls_detail-trandate+14(2)
                  ls_detail-trandate+17(2)
             INTO ls_offline_data-valor.

      ls_offline_data-sender_iban      = ls_detail-iban.
      ls_offline_data-transaction_type            = ls_detail-swifttransactioncode.
      ls_offline_data-transaction_type            = ls_offline_data-transaction_type+1(10).
      ls_offline_data-sender_branch         = ls_detail-branchname.

      APPEND ls_offline_data TO et_bank_data.
      clear ls_offline_data.
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
      lv_opening_balance  = lv_closing_balance = ls_json_response-balance.
    ENDIF.

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