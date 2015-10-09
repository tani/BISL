defmodule BISL do
	@src "((_lambda () #{File.read!("lib/core.lsp")}))"

	def main([]) do
		initialize
		repl
	end

  def initialize() do
    Agent.start_link(fn -> [
      {:TRUE,true},
      {:FALSE,false}
      ] end)
		|> elem(1) |> Process.register(:vt)

    Agent.start_link(fn -> [
      {:_CONS, &_cons/1},
      {:_IF,   &_if/2},
      {:_QUOTE,&_quote/2},
      {:_LAMBDA,&_lambda/2},
      {:_DEFUN,&_defun/2},
      {:_DEFVAR,&_defvar/2},
      {:_DEFMACRO,&_defmacro/2},
      {:_READ,&_read/0},
      {:_LOAD,&_load/1},
      {:_EVAL,&_eval/2},
      {:_P,&_p/1},
      {:_ERLANG,&_erlang/2},
      {:_BACKQUOTE,&_backquote/2},
      {:_FUNCTION,&_function/2}
      ] end)
		|> elem(1) |> Process.register(:ft)

    Agent.start_link(fn -> [
      {:_QUOTE, true},
      {:_BACKQUOTE, true},
      {:_DEFUN, true},
      {:_DEFVAR,true},
      {:_DEFMACRO,true},
      {:_EVAL,true},
      {:_FUNCTION,true},
      {:_ERLANG,true},
      {:_IF,true},
      {:_LAMBDA,true}
    ] end)
		|> elem(1) |> Process.register(:macro)

		@src |> to_char_list
		     |> :lexer.string |> elem(1)
		     |> :parser.parse |> elem(1)
		     |> _eval(:vt)
  end

  def sym_get(tb,name),
    do: Agent.get tb, &(&1[name])
  def sym_add(tb,name,var),
    do: Agent.update tb, &([{name,var}|&1])
  def sym_delete(tb,name),
    do: Agent.update tb, &(List.delete &1, name)
  def sym_table_delete(tb),
      do: Agent.stop tb
  def sym_table_copy(tb) do
		(fn -> Agent.get(tb,fn x -> x end) end)
		|> Agent.start_link |> elem(1)
  end

  def _p([obj]), do: IO.inspect obj

  def _eval([cmd|args],env) when is_list(cmd),
    do: _eval(cmd,env).(Enum.map(args,&(_eval &1,env)))
  def _eval([cmd|args],env) do
    if sym_get(:macro,cmd) do
      sym_get(:ft, cmd).(args,env)
    else
      sym_get(:ft, cmd).(Enum.map(args,&(_eval &1,env)))
    end
  end
  def _eval(val,env) when is_atom(val), do: sym_get env, val
  def _eval(val,_env), do: val

  def _read() do
  	IO.gets("")
		|> to_char_list
		|> :lexer.string |> elem(1)
		|> :parser.parse |> elem(1)
		|> _eval(:vt)
	end

  def _load(file) do
    "((_lambda () #{File.read!(file)}))"
		 |> to_char_list
     |> :lexer.string |> elem(1)
		 |> :parser.parse |> elem(1)
		 |> _eval(:vt)
  end

  def _if([test,then],env) do
    if _eval test,env do
      _eval then,env
    end
  end

  def _if([test,then,otherwise],env) do
    if _eval test,env do
      _eval then,env
    else
      _eval otherwise,env
    end
  end

  def _lambda([args|body],vt) do
    fn vars ->
      env = sym_table_copy vt
      n = Enum.find_index(args,fn x -> x == :"&REST" end)
      if n do
        for {a,v}<-Enum.zip(Enum.take(args,n),Enum.take(vars,n)), do: sym_add env, a, v
        sym_add env, Enum.at(args,n+1), Enum.drop(vars,n)
      else
        for {a,v}<-Enum.zip(args,vars),do: sym_add env, a, v
      end
      ret = Enum.map(body, &(_eval &1,env))
#      sym_table_delete env
      List.last ret
    end
  end

  def _function([obj],_env), do: sym_get(:ft,obj)
  def _defun([name|[args|body]],env), do: sym_add(:ft, name, _lambda([args|body],env))
  def _defvar([name,val],env),do: sym_add env, name,val
  def _quote([args],_env),do: args
  def _cons([val,list]),  do: [val|list]

  def _erlang([module,function|args],env) do
    fun = function
          |> Atom.to_string
          |> String.downcase
          |> String.to_atom
    mod = module
          |> Atom.to_string
          |> String.downcase
          |> String.to_atom
    apply mod,fun,Enum.map(args,&(_eval &1,env))
  end

  def _defmacro([name|[args|body]],_env) do
    sym_add :macro,name,true
    sym_add :ft,name,fn vars,vt ->
      env = sym_table_copy vt
      n = Enum.find_index(args,fn x -> x == :"&REST" end)
      if n do
        for {a,v}<-Enum.zip(Enum.take(args,n),Enum.take(vars,n)), do: sym_add env, a, v
        sym_add env, Enum.at(args,n+1), Enum.drop(vars,n)
      else
        for {a,v}<-Enum.zip(args,vars), do: sym_add env, a, v
      end
      ret = Enum.map(Enum.map(body, &(_eval &1,env)), &(_eval &1,env))
#      sym_table_delete env
      List.last ret
      end
  end

  def _backquote([[[:_UNQUOTE,exp]|rest]],env),
    do: [_eval(exp,env)|_backquote([rest],env)]
  def _backquote([[[:_SPLICE,exp]|rest]],env),
    do: _eval(exp,env) ++ _backquote([rest],env)
  def _backquote([[hd|tl]],env),
    do: [_backquote([hd],env)|_backquote([tl],env)]
  def _backquote([obj],_env), do: obj

  def repl() do
    IO.write "? "
		_read |> _eval(:vt) |> IO.inspect
    repl
  end
end
