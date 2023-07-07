# GViNT - Godot Visual Novel Tools
## How it works
The core purpose of GViNT is to bring simplified scripting for cutscenes and dialogue into the Godot engine, with full undo/redo and save/reload support. The way it accomplishes this is by translating source scripts of GDScript-style statements stripped down of any GDScript context into proper GDScript files containing the translated source statements. Corresponding GvintRuntime nodes execute said translated GDScript files and can be extended from to form an interface between the stripped-down source scripts and arbitrary game systems. Script statements get translated to operations on the runtime node, for instance a display text statement will result in calling the `display_text` method on the runtime node, and a `do_a_thing()` call function statement will call the runtime's `do_a_thing` method (if present, otherwise it will result in an error at runtime). The same goes for setting and accessing variables - `foo` becomes `runtime.foo` etc. All variables and methods declared on the runtime node are available in script, which makes for a very powerful and flexible system.

## Syntax

### Set variable statement

`<target> <operator> <value expression>`

For example: 
```
foo = 42
foo.get_bar().some_property = randi()
foo = SomeSingleton.get_value()
```

### Call function statement
`<target>(<parameter list>)`

for example:

`do_a_thing("a", "b")`

In stateful mode, a corresponding `undo_<method name>` method will - if defined on the method call target - be called when undoing the statement.

### Display text statement
`<string literal>` OR `<parameter list>: <string literal>`

Calls the runtime's `display_text` method with two arguments - the text to be displayed, and an array containing the parameters. When using parameters, the wrapping quotes around the string literal can be omitted - the coma is sufficient to mark the following characters as being a string literal.

For example:
```
"Hello, world!"
foo: Hello, world!
foo, bar: "Lorem ipsum dolor sit amet"
```

### Conditional statement
`if <condition> {`

 ` <nested statements>`
  
`}`

Optional else/elif blocks.

For example:

```
if foo == 42 {
  "Answer to life, universe, and everything"
}
elif foo == 1337 {
  "leet!"
}
else {
  "foobar"
}
```

## Coroutines
GViNT makes use of GDScript coroutines using yield in order to control when the next statement is executed. If the callback of a call function (or display text) statement yields, or the value expression of a set variable statement returns a `GDScriptFunctionState` object, the runtime node will wait until the resulting coroutine is completed before executing the next statement. For example, the `display_text` method would yield on a signal to advance the dialogue, which would cause the runtime node to yield and resume execution once the signal is emitted. Non-yielding statements get processed immediately.


## Variable naming convention
During the translation process, non-global identifiers get prefixed with "runtime.", so for instance `some_property` becomes `runtime.some_property`. However, this prefix ought to be omitted for built-in types and singletons. This is achieved based on the capitalisation of the first letter of the identifier. For example, `Vector2` or `SomeSingleton` both start with capital letters, and would be translated unchanged. The translator only checks whether the first letter is uppercase or lowercase, rather than doing all the work of checking whether the identifier is a built-in type or an existing singleton. This means that variable names must start with a lowercase letter or an underscore! Otherwise, they will be translated incorrectly.


## GvintVariable
In stateless mode, a variable can have any arbitrary value possible in GDScript. However, in stateful mode, it must be possible to undo set variable statements and to serialize the state of runtime variables. These limitations are enforced in stateful mode by wrapping runtime variables in `GvintVariable` objects, which automatically store the history of the variable's value and enforce type limitations. A `GvintVariable` can only store primitive datatypes and `Resource` types.

Due to translator limitations, it is sometimes necessary to distinguish between the value of a `GvintVariable` and the `GvintVariable` object itself. Set variable statements function as expected - `foo = 42` will create a `GvintVariable` and write 42 to its value. However, `if foo == 42` will compare the literal value 42 to the `GvintVariable` **wrapper object**. In order to read the value of a `GvintVariable` object, the `value` property must be accessed, for example `if foo.value == 42`.


## Editor
The plugin comes with a basic script editor. It is recommended to use it, as it will automatically translate scripts when they are saved. If using an external editor, the script is only translated upon execution. This could potentially result in a situation where a script isn't translated before exporting the final project, which would make it impossible to execute.

## API

### GvintRuntimeStateless
Basic script runtime that can execute scripts.

#### start(script_filename: String)
Executes the script based on the provided filename. If the filename does not start with "res://", a configurable prefix ("res://Story/" by default) is added. If the filename does not contain an extension, a configurable suffix (".txt" by default) is added. Can be called from inside a script in order to nest script execution. Once the nested script is completed, the execution of the calling script will resume.

#### stop()
Ends script execution.

#### create_runtime_variable(identifier: String, value = null)
Creates a runtime variable based on the provided data. Equivalent to `runtime_variables[identifier] = value`.

#### _init_runtime_variables()
Virtual methoid called just before the script execution starts. Meant to be used for initializing runtime variables.

### GvintRuntimeStateful
Extends GvintRuntimeStateless to support full undo/redo as well as save/reload.

#### create_runtime_variable(identifier: String, value = null)
Creates and initializes a new `GvintVariable` object based on the provided data.

#### step_backwards()
Executes the script in reverse until a yielding statement is reached.

#### save_state(savefile_path: String)
Saves the runtime's state to the provided filename.

#### load_state(savefile_path: String)
Loads runtime state data from the file at `savefile_path` and restores the state.

#### _save_state() -> Dictionary
Virtual method called while saving the state, must return a JSON-compatible `Dictionary` containing data that's supposed to be preserved in the savestate.

#### _load_state(savestate: Dictionary)
Virtual method called while reloading the state, must restore the runtime's state based on data provided by `_save_state()`.

### GvintVariable
Wrapper object around GDScript variables meant to help undo/redo and serialization in stateful mode.

#### undo_last_change()
Restores the previous value of the variable.

#### stateless_set(value)
Sets the value of the variable without storing the current value in its history.

#### serialize_state() -> Array
Returns a JSON-compatible array containing the variable's value history.

#### load_state(savestate: Array)
Restores the state of the object based on data provided by `serialilze_state()`

## Future plans:

Godot 4.x port

Template VN project
