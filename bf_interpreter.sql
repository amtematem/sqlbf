with params as
  (select '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.' bf_code
        , 10 memory_size
     from dual
  )
, params2 as
  (select params.bf_code || '+' bf_code
        , params.memory_size
     from params
  )
, stairs(n, f) as
  (select 0 n
        , 0 f
   from dual
   union all
   select stairs.n+1
        , case
            when substr(params2.bf_code, stairs.n+1, 1) = '[' then 1
            when substr(params2.bf_code, stairs.n+1, 1) = ']' then -1
            else 0
          end + stairs.f
     from stairs
        , params2
    where stairs.n <= length(params2.bf_code)
  )
, pairs as
  (select stairs.n
        , case
            when substr(params2.bf_code, stairs.n, 1) = '['
            then (select min(stairs2.n)
                    from stairs stairs2
                   where stairs2.n > stairs.n
                     and stairs2.f = stairs.f-1
                 )
            when substr(params2.bf_code, stairs.n, 1) = ']'
            then (select max(stairs2.n)+1
                    from stairs stairs2
                   where stairs2.n < stairs.n
                     and stairs2.f = stairs.f
                 )
            else 0
          end match_number
     from stairs
        , params2
    where stairs.n >= 1
      and stairs.n <= length(params2.bf_code)
  )
, execution(step, code_pointer, data_pointer, memory, output_string) as
  (select 0 step
        , 1 code_pointer
        , 0 data_pointer
        , lpad('0', memory_size*2, '0') memory
        , '' output_string
     from params2
   union all
   select e.step + 1 step
        , case
            when substr(params2.bf_code, e.code_pointer, 1) = '[' then
              case
                when substr(e.memory, e.data_pointer*2+1, 2) = '00' then (select pairs.match_number from pairs where pairs.n = e.code_pointer) + 1
                else e.code_pointer + 1
              end
            when substr(params2.bf_code, e.code_pointer, 1) = ']' then
              case
                when substr(e.memory, e.data_pointer*2+1, 2) = '00' then e.code_pointer + 1
                else (select pairs.match_number from pairs where pairs.n = e.code_pointer) + 1
              end
            else e.code_pointer + 1
          end code_pointer
        , case
            when substr(params2.bf_code, e.code_pointer, 1) = '>' then mod(e.data_pointer + 1, params2.memory_size)
            when substr(params2.bf_code, e.code_pointer, 1) = '<' then mod(e.data_pointer - 1 + params2.memory_size, params2.memory_size)              
            else e.data_pointer
          end data_pointer
        , case
            when substr(params2.bf_code, e.code_pointer, 1) = '+' then substr(e.memory, 1, e.data_pointer*2) || trim(to_char(mod(to_number(substr(e.memory, e.data_pointer*2+1, 2), 'XX')+1, 256), '0X')) || substr(e.memory, e.data_pointer*2+3)
            when substr(params2.bf_code, e.code_pointer, 1) = '-' then substr(e.memory, 1, e.data_pointer*2) || trim(to_char(mod(to_number(substr(e.memory, e.data_pointer*2+1, 2), 'XX')+256-1, 256), '0X')) || substr(e.memory, e.data_pointer*2+3)
            else e.memory
          end memory
        , case
            when substr(params2.bf_code, e.code_pointer, 1) = '.'
            then e.output_string || chr(to_number(substr(e.memory, e.data_pointer*2+1, 2), 'XX'))
            else e.output_string
          end output_string
     from execution e
        , params2
    where e.code_pointer = e.code_pointer
      and e.data_pointer = e.data_pointer
      and e.memory = e.memory
      and e.code_pointer <= length(params2.bf_code)
  )
select *
  from execution
 order by step desc
