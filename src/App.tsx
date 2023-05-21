import "./App.css"
import Sketch from "./Sketch"
import { Canvas } from "@react-three/fiber"
import { OrbitControls } from "@react-three/drei"

function App() {
  return (
    <div className='App'>
      <Canvas
        camera={{
          position: [0, 0, 15],
        }}
      >
        <OrbitControls />
        <Sketch />
      </Canvas>
    </div>
  )
}

export default App
