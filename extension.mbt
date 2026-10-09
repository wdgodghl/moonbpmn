///|
/// Namespaced application metadata attached to a BPMN model element.
pub(all) struct ExtensionProperty {
  namespace_uri : String
  name : String
  value : String
} derive(Eq, Debug)

///|
pub extend ExtensionProperty with Eq::{equal, not_equal}

///|
pub extend ExtensionProperty with Debug::{to_repr}

///|
pub fn ExtensionProperty::new(
  namespace_uri : String,
  name : String,
  value : String,
) -> ExtensionProperty {
  { namespace_uri, name, value, }
}

///|
fn set_extension_property(
  properties : Array[ExtensionProperty],
  property : ExtensionProperty,
) -> Unit {
  for index, existing in properties {
    if existing.namespace_uri == property.namespace_uri &&
      existing.name == property.name {
      properties[index] = property
      return
    }
  }
  properties.push(property)
}

///|
fn get_extension_property(
  properties : Array[ExtensionProperty],
  namespace_uri : String,
  name : String,
) -> String? {
  for property in properties {
    if property.namespace_uri == namespace_uri && property.name == name {
      return Some(property.value)
    }
  }
  None
}

///|
fn remove_extension_property(
  properties : Array[ExtensionProperty],
  namespace_uri : String,
  name : String,
) -> Bool {
  for index, property in properties {
    if property.namespace_uri == namespace_uri && property.name == name {
      ignore(properties.remove(index))
      return true
    }
  }
  false
}
