declare
l_quote_id number := 4361808;
l_version_number number := 2;
l_msg_json varchar2(3000);
l_publish_result number;--4234230.2
begin
             UPDATE wwt_quote.quote
             SET status_code = 'EXP',
              last_update_date = sysdate,
              wwt_last_updated_by = 0
             WHERE quote_id = l_quote_id;
 
             l_msg_json := '{' ||
                              '"quoteId":' || l_quote_id || ',' ||
                              '"quoteVersionNumber": ' || l_version_number || ',' ||
                              '"status":"exp",' ||
                              '"headerStatus":"exp"' ||
                           '}';
 
             wwt_mq.wwt_amqp.amqp_publish(p_exchange   => 'wwt.quote.status.change',
                                         p_appid      => 'ORACLEDB',
                                         p_routingkey => 'status.change.exp',
                                         p_message    => l_msg_json,
                                         x_published  => l_publish_result);
                                        
            commit;
end;