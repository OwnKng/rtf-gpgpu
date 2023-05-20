import "./App.css"
import Sketch from "./Sketch"
import { Canvas } from "@react-three/fiber"

function App() {
  return (
    <div className='App'>
      <Canvas
        orthographic
        camera={{
          position: [0, 0, 15],
          zoom: 30,
        }}
      >
        <Sketch />
      </Canvas>
    </div>
  )
}

export default App
