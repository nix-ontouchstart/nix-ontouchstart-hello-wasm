use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn main() {
    let window = web_sys::window().expect("no global `window` exists");
    let document = window.document().expect("should have a document on window");
    let body = document.body().expect("document should have a body");

    let val = document.create_element("h2").unwrap();
    val.set_text_content(Some("nix-ontouchstart-hello-wasm (dynamic wasm content)"));
    body.append_child(&val).unwrap();
}

