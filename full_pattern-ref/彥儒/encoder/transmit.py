import numpy as np

class SimpleBPSKModulationAWGN:
    """Simple model of BPSK-modulation + AWGN channel.

    Implemented for the comparison with the SC decoder proposed by H. Vangala,
    E. Viterbo, and Yi Hong (See `PlotPC and PlotPCSystematic`):
    https://ecse.monash.edu/staff/eviterbo/polarcodes.html.

    """
    noise_power = 2.0

    def __init__(self, fec_rate: float):
        self.fec_rate = fec_rate

    def transmit(self, message: np.array,
                 snr_db: float,
                 with_noise: bool = True) -> np.array:
        """Transmit BPSK-modulated message over AWGN message."""
        symbol_energy = self._compute_symbol_energy(snr_db, self.fec_rate)
        transmitted = self._modulate(message, symbol_energy)
        # print(transmitted)
        if with_noise:
            transmitted = self._add_noise(transmitted, self.noise_power)
        # print(transmitted)
        return self._llr_detection(transmitted, symbol_energy, self.noise_power)  # noqa
    @staticmethod
    def _compute_symbol_energy(snr_db, fec_rate):
        snr = np.power(10, snr_db / 10)
        # print("snr = ", snr)
        return snr
    @staticmethod
    def _modulate(message: np.array, symbol_energy: float) -> np.array:
        """BPSK modulation."""
        return (2 * message - 1) * np.sqrt(symbol_energy)
    @staticmethod
    def _add_noise(signal: np.array, noise_power: float) -> np.array:
        """Add AWGN noise to signal."""
        noise = np.sqrt(noise_power / 2) * np.random.randn(signal.size)
        # print(signal)
        return signal + noise
    @staticmethod
    def _llr_detection(signal: np.array, symbol_energy: float, noise_power: float) -> np.array:
        """LLR detection of BPSK signal with AWGN."""
        return -2 * signal * np.sqrt(symbol_energy)