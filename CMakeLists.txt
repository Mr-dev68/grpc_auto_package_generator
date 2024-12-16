cmake_minimum_required(VERSION 3.8)

project(grpc_generator C CXX)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/common.cmake)

# finding protobuf package and include the directories  
find_package(Protobuf REQUIRED)
include_directories(${Protobuf_INCLUDE_DIRS})

# set the directories containing the proto files ,these are examples
set(PROTO_DIRS 
    "${CMAKE_CURRENT_SOURCE_DIR}/protos/example1"
    "${CMAKE_CURRENT_SOURCE_DIR}/protos/example2"
)

# Base directory for generated source and headers
set(GENERATED_PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generated")

# create the output directory if it doesn't exist (optional)
file(MAKE_DIRECTORY ${GENERATED_PROTO_DIR})

# Path to the common_services.proto file(optional) if you have msgs which are common between some/all of your services add them to the common.proto
set(COMMON_PROTO "${CMAKE_CURRENT_SOURCE_DIR}/protos/common.proto")

# Generate the protobuf files for common_services.proto only once
set(COMMON_PROTO_SRCS "${GENERATED_PROTO_DIR}/common.pb.cc")
set(COMMON_PROTO_HDRS "${GENERATED_PROTO_DIR}/common.pb.h")
set(COMMON_GRPC_SRCS "${GENERATED_PROTO_DIR}/common.grpc.pb.cc")
set(COMMON_GRPC_HDRS "${GENERATED_PROTO_DIR}/common.grpc.pb.h")
# this is the main command, generating cpp files for common proto.
add_custom_command(
    OUTPUT "${COMMON_PROTO_SRCS}" "${COMMON_PROTO_HDRS}" "${COMMON_GRPC_SRCS}" "${COMMON_GRPC_HDRS}"
    COMMAND ${_PROTOBUF_PROTOC}
    ARGS --cpp_out "${GENERATED_PROTO_DIR}"
         --grpc_out "${GENERATED_PROTO_DIR}"
         -I ${CMAKE_CURRENT_SOURCE_DIR}/protos
         --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
         ${COMMON_PROTO}
    DEPENDS ${COMMON_PROTO}
    COMMENT "Generating C++ protobuf files from ${COMMON_PROTO} with custom extensions"
)

add_library(common_protobuf STATIC
    ${COMMON_PROTO_SRCS}
    ${COMMON_GRPC_SRCS}
)
target_include_directories(common_protobuf PUBLIC ${GENERATED_PROTO_DIR})
target_link_libraries(common_protobuf ${Protobuf_LIBRARIES})

# Iterate over each directory and generate protobuf files
foreach(PROTO_DIR ${PROTO_DIRS})
    # Get the name of the directory 
    get_filename_component(LIB_NAME ${PROTO_DIR} NAME)

    # Collect all .proto files in the directory
    file(GLOB PROTO_FILES "${PROTO_DIR}/*.proto")

    # Initialize lists to hold generated source and header files
    set(PROTO_SRCS)
    set(PROTO_HDRS)

    foreach(PROTO_FILE ${PROTO_FILES})
        # Exclude common_services.proto from being processed again
        if(${PROTO_FILE} STREQUAL ${COMMON_PROTO})
            continue()
        endif()

        # Get the base name of the proto file (without extension and path)
        get_filename_component(PROTO_BASENAME ${PROTO_FILE} NAME_WE)
        
        # Set the custom output files with .hpp and .cpp extensions
        set(rg_proto_srcs "${GENERATED_PROTO_DIR}/${PROTO_BASENAME}.pb.cc")
        set(rg_proto_hdrs "${GENERATED_PROTO_DIR}/${PROTO_BASENAME}.pb.h")
        set(rg_grpc_srcs "${GENERATED_PROTO_DIR}/${PROTO_BASENAME}.grpc.pb.cc")
        set(rg_grpc_hdrs "${GENERATED_PROTO_DIR}/${PROTO_BASENAME}.grpc.pb.h")

        # Add custom command to generate the files using protoc
        add_custom_command(
            OUTPUT "${rg_proto_srcs}" "${rg_proto_hdrs}" "${rg_grpc_srcs}" "${rg_grpc_hdrs}"
            COMMAND ${_PROTOBUF_PROTOC}
            ARGS --cpp_out "${GENERATED_PROTO_DIR}"
                 --grpc_out "${GENERATED_PROTO_DIR}"
                 -I ${PROTO_DIR}
                 -I ${CMAKE_CURRENT_SOURCE_DIR}/protos # Include the root proto directory for common_services.proto
                 --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
                 ${PROTO_FILE}
            DEPENDS ${PROTO_FILE} ${COMMON_PROTO}
            COMMENT "Generating C++ protobuf files from ${PROTO_FILE} with custom extensions"
        )

        # Append the generated files to the source list
        list(APPEND PROTO_SRCS ${rg_proto_srcs} ${rg_grpc_srcs})
        list(APPEND PROTO_HDRS ${rg_grpc_hdrs} ${rg_proto_hdrs})
    endforeach()

    # Create a static library for the generated protobuf files
    add_library(${LIB_NAME}_protobuf STATIC ${PROTO_SRCS})
    target_include_directories(${LIB_NAME}_protobuf PUBLIC ${GENERATED_PROTO_DIR})
    target_link_libraries(${LIB_NAME}_protobuf ${Protobuf_LIBRARIES} common_protobuf)

    # Install the library and header files
    install(TARGETS ${LIB_NAME}_protobuf
            ARCHIVE DESTINATION lib/${LIB_NAME}
            LIBRARY DESTINATION lib/${LIB_NAME}
            RUNTIME DESTINATION bin/${LIB_NAME})

    install(FILES ${PROTO_HDRS} DESTINATION include/${LIB_NAME})
endforeach()
