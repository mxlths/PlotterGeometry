from setuptools import setup, find_packages

setup(
    name="geometron",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "numpy",
        "scipy",
        "PyQt6",
        "pyqtgraph",
        "vispy",
        "svgwrite",
        "lxml",
        "attrs"
    ],
    entry_points={
        'console_scripts': [
            'geometron=geometron.main:main',
        ],
    },
    python_requires=">=3.8",
) 