
# Macro to compile a source file to identify the compiler.  This is
# used internally by CMake and should not be included by user code.
# If successful, sets CMAKE_<lang>_COMPILER_ID and CMAKE_<lang>_PLATFORM_ID

MACRO(CMAKE_DETERMINE_COMPILER_ID lang flagvar src)
  # Store the compiler identification source file.
  SET(CMAKE_${lang}_COMPILER_ID_SRC "${src}")
  IF(WIN32 AND NOT CYGWIN)
    # This seems to escape spaces:
    #FILE(TO_NATIVE_PATH "${CMAKE_${lang}_COMPILER_ID_SRC}"
    #  CMAKE_${lang}_COMPILER_ID_SRC)
    STRING(REGEX REPLACE "/" "\\\\" CMAKE_${lang}_COMPILER_ID_SRC
      "${CMAKE_${lang}_COMPILER_ID_SRC}")
  ENDIF(WIN32 AND NOT CYGWIN)

  # Make sure user-specified compiler flags are used.
  IF(CMAKE_${lang}_FLAGS)
    SET(CMAKE_${lang}_COMPILER_ID_FLAGS ${CMAKE_${lang}_FLAGS})
  ELSE(CMAKE_${lang}_FLAGS)
    SET(CMAKE_${lang}_COMPILER_ID_FLAGS $ENV{${flagvar}})
  ENDIF(CMAKE_${lang}_FLAGS)

  # Create an empty directory in which to run the test.
  SET(CMAKE_${lang}_COMPILER_ID_DIR ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CompilerId${lang})
  FILE(REMOVE_RECURSE ${CMAKE_${lang}_COMPILER_ID_DIR})
  FILE(MAKE_DIRECTORY ${CMAKE_${lang}_COMPILER_ID_DIR})

  # Compile the compiler identification source.
  STRING(REGEX REPLACE " " ";" CMAKE_${lang}_COMPILER_ID_FLAGS_LIST "${CMAKE_${lang}_COMPILER_ID_FLAGS}")
  IF(COMMAND EXECUTE_PROCESS)
    EXECUTE_PROCESS(
      COMMAND ${CMAKE_${lang}_COMPILER} ${CMAKE_${lang}_COMPILER_ID_FLAGS_LIST} ${CMAKE_${lang}_COMPILER_ID_SRC}
      WORKING_DIRECTORY ${CMAKE_${lang}_COMPILER_ID_DIR}
      OUTPUT_VARIABLE CMAKE_${lang}_COMPILER_ID_OUTPUT
      ERROR_VARIABLE CMAKE_${lang}_COMPILER_ID_OUTPUT
      RESULT_VARIABLE CMAKE_${lang}_COMPILER_ID_RESULT
      )
  ELSE(COMMAND EXECUTE_PROCESS)
    EXEC_PROGRAM(
      ${CMAKE_${lang}_COMPILER} ${CMAKE_${lang}_COMPILER_ID_DIR}
      ARGS ${CMAKE_${lang}_COMPILER_ID_FLAGS_LIST} \"${CMAKE_${lang}_COMPILER_ID_SRC}\"
      OUTPUT_VARIABLE CMAKE_${lang}_COMPILER_ID_OUTPUT
      RETURN_VALUE CMAKE_${lang}_COMPILER_ID_RESULT
      )
  ENDIF(COMMAND EXECUTE_PROCESS)

  # Check the result of compilation.
  IF(CMAKE_${lang}_COMPILER_ID_RESULT)
    # Compilation failed.
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Compiling the ${lang} compiler identification source file \""
      "${CMAKE_${lang}_COMPILER_ID_SRC}\" failed with the following output:\n"
      "${CMAKE_${lang}_COMPILER_ID_RESULT}\n"
      "${CMAKE_${lang}_COMPILER_ID_OUTPUT}\n\n")
    MESSAGE(FATAL_ERROR "Compiling the ${lang} compiler identification source file \""
      "${CMAKE_${lang}_COMPILER_ID_SRC}\" failed with the following output:\n"
      "${CMAKE_${lang}_COMPILER_ID_RESULT}\n"
      "${CMAKE_${lang}_COMPILER_ID_OUTPUT}\n\n")
  ELSE(CMAKE_${lang}_COMPILER_ID_RESULT)
    # Compilation succeeded.
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
      "Compiling the ${lang} compiler identification source file \""
      "${CMAKE_${lang}_COMPILER_ID_SRC}\" succeeded with the following output:\n"
      "${CMAKE_${lang}_COMPILER_ID_OUTPUT}\n\n")

    # Find the executable produced by the compiler.
    SET(CMAKE_${lang}_COMPILER_ID_EXE)
    GET_FILENAME_COMPONENT(CMAKE_${lang}_COMPILER_ID_SRC_BASE ${CMAKE_${lang}_COMPILER_ID_SRC} NAME_WE)
    FOREACH(name a.out a.exe ${CMAKE_${lang}_COMPILER_ID_SRC_BASE}.exe)
      IF(EXISTS ${CMAKE_${lang}_COMPILER_ID_DIR}/${name})
        SET(CMAKE_${lang}_COMPILER_ID_EXE ${CMAKE_${lang}_COMPILER_ID_DIR}/${name})
      ENDIF(EXISTS ${CMAKE_${lang}_COMPILER_ID_DIR}/${name})
    ENDFOREACH(name)

    # Check if the executable was found.
    IF(CMAKE_${lang}_COMPILER_ID_EXE)
      # The executable was found.
      FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
        "Compilation of the ${lang} compiler identification source \""
        "${CMAKE_${lang}_COMPILER_ID_SRC}\" produced \""
        "${CMAKE_${lang}_COMPILER_ID_EXE}\"\n\n")

      # Read the compiler identification string from the executable file.
      FILE(STRINGS ${CMAKE_${lang}_COMPILER_ID_EXE}
        CMAKE_${lang}_COMPILER_ID_STRINGS LIMIT_COUNT 2 REGEX "INFO:")
      FOREACH(info ${CMAKE_${lang}_COMPILER_ID_STRINGS})
        IF("${info}" MATCHES ".*INFO:compiler\\[([^]]*)\\].*")
          STRING(REGEX REPLACE ".*INFO:compiler\\[([^]]*)\\].*" "\\1"
            CMAKE_${lang}_COMPILER_ID "${info}")
        ENDIF("${info}" MATCHES ".*INFO:compiler\\[([^]]*)\\].*")
        IF("${info}" MATCHES ".*INFO:platform\\[([^]]*)\\].*")
          STRING(REGEX REPLACE ".*INFO:platform\\[([^]]*)\\].*" "\\1"
            CMAKE_${lang}_PLATFORM_ID "${info}")
        ENDIF("${info}" MATCHES ".*INFO:platform\\[([^]]*)\\].*")
      ENDFOREACH(info)

      # Check the compiler identification string.
      IF(CMAKE_${lang}_COMPILER_ID)
        # The compiler identification was found.
        FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
          "The ${lang} compiler identification is ${CMAKE_${lang}_COMPILER_ID}\n\n")
      ELSE(CMAKE_${lang}_COMPILER_ID)
        # The compiler identification could not be found.
        FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
          "The ${lang} compiler identification could not be found in \""
          "${CMAKE_${lang}_COMPILER_ID_EXE}\"\n\n")
      ENDIF(CMAKE_${lang}_COMPILER_ID)
    ELSE(CMAKE_${lang}_COMPILER_ID_EXE)
      # The executable was not found.
      FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
        "Compilation of the ${lang} compiler identification source \""
        "${CMAKE_${lang}_COMPILER_ID_SRC}\" did not produce an executable in "
        "${CMAKE_${lang}_COMPILER_ID_DIR} "
        "with a name known to CMake.\n\n")
    ENDIF(CMAKE_${lang}_COMPILER_ID_EXE)

    IF(CMAKE_${lang}_COMPILER_ID)
      MESSAGE(STATUS "The ${lang} compiler identification is "
        "${CMAKE_${lang}_COMPILER_ID}")
    ELSE(CMAKE_${lang}_COMPILER_ID)
      MESSAGE(STATUS "The ${lang} compiler identification is unknown")
    ENDIF(CMAKE_${lang}_COMPILER_ID)
  ENDIF(CMAKE_${lang}_COMPILER_ID_RESULT)
ENDMACRO(CMAKE_DETERMINE_COMPILER_ID)
